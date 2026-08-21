import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../../core/config/env.dart';
import '../../../../core/error/exceptions.dart';

/// Result of a completed OIDC authorization — enough to persist a session
/// and let the caller fetch the profile through the normal REST path.
class OidcTokens {
  const OidcTokens({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final String? refreshToken;
  final String? idToken;
}

/// The system-browser OIDC authorization-code + PKCE flow against `idp`.
///
/// This is the same flow every W6-wired web platform uses
/// (shared/src/auth-client/oidc-client.ts) and the same doctrine
/// idp/src/modules/oidc/controllers/login.controller.ts states directly:
/// credentials are entered at the issuer, in the issuer's own hosted login
/// page rendered inside the system browser — never inside this app. Only an
/// authorization code, then a token, ever reaches the client.
///
/// `FlutterAppAuth` drives the platform's own browser-tab/Custom-Tabs
/// implementation (Chrome Custom Tabs on Android, `ASWebAuthenticationSession`
/// on iOS) rather than an in-app WebView, which is what makes this resistant
/// to a malicious app screen-scraping the password field — a WebView-hosted
/// login form would have no such isolation.
abstract class OidcAuthDataSource {
  /// Launches the system browser, completes the PKCE exchange, and returns
  /// tokens. Throws [AuthException] if the user cancels or the exchange fails.
  Future<OidcTokens> authorize();

  /// Exchanges a stored refresh token for a fresh access token, without
  /// involving the browser. Returns `null` if the refresh token itself has
  /// expired or been revoked — the caller must fall back to [authorize].
  Future<OidcTokens?> refresh(String refreshToken);

  /// RP-initiated logout — revokes the session at the issuer, not just
  /// locally, so a stolen refresh token can't outlive a "signed out" tap.
  Future<void> endSession({String? idToken});
}

class OidcAuthDataSourceImpl implements OidcAuthDataSource {
  OidcAuthDataSourceImpl([FlutterAppAuth? appAuth])
      : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  AuthorizationServiceConfiguration get _serviceConfig =>
      AuthorizationServiceConfiguration(
        authorizationEndpoint: '${Env.idpOrigin}/oidc/authorize',
        tokenEndpoint: '${Env.idpOrigin}/oidc/token',
        endSessionEndpoint: '${Env.idpOrigin}/oidc/end_session',
      );

  @override
  Future<OidcTokens> authorize() async {
    try {
      final AuthorizationTokenResponse result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Env.oidcClientId,
          Env.oidcRedirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: Env.oidcScopes,
          // Public client, PKCE-only — no client secret exists to send, by
          // design (see seed-oidc-clients.ts's header comment).
          preferEphemeralSession: true,
        ),
      );
      final String? accessToken = result.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthException('The identity provider returned no access token.');
      }
      return OidcTokens(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        idToken: result.idToken,
      );
    } on FlutterAppAuthUserCancelledException {
      throw const AuthException('Sign-in was cancelled.');
    } on FlutterAppAuthPlatformException catch (error) {
      throw AuthException(error.message ?? 'Sign-in failed.');
    }
  }

  @override
  Future<OidcTokens?> refresh(String refreshToken) async {
    try {
      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          Env.oidcClientId,
          Env.oidcRedirectUri,
          serviceConfiguration: _serviceConfig,
          refreshToken: refreshToken,
          grantType: 'refresh_token',
          scopes: Env.oidcScopes,
        ),
      );
      final String? accessToken = result.accessToken;
      if (accessToken == null || accessToken.isEmpty) return null;
      return OidcTokens(
        accessToken: accessToken,
        // A rotated refresh token replaces the old one; an absent one means
        // the issuer kept the same token valid (OidcTokenService rotates on
        // every use, so in practice this is always present).
        refreshToken: result.refreshToken ?? refreshToken,
        idToken: result.idToken,
      );
    } on Object {
      // Any failure here — expired, revoked, network — means "cannot renew
      // silently"; the caller re-authorizes rather than surfacing this as a
      // hard error.
      return null;
    }
  }

  @override
  Future<void> endSession({String? idToken}) async {
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          idTokenHint: idToken,
          postLogoutRedirectUrl: Env.oidcLogoutRedirectUri,
          serviceConfiguration: _serviceConfig,
        ),
      );
    } on Object {
      // Best-effort: the local session is cleared regardless by the caller,
      // and a failed remote end-session here would otherwise block logout.
    }
  }
}
