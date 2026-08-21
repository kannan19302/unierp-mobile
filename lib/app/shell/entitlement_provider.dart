import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/network/api_paths.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// The tenant's installed-module slugs, sourced from the same
/// `/saas/installed-apps` endpoint the web Application Wizard (W7) and
/// command palette read from — so mobile never shows a module the tenant
/// hasn't installed, matching web rather than drifting from it.
///
/// `app_shell.dart`'s bottom-nav/rail destinations were previously a fixed
/// list with no entitlement check at all; every module was reachable
/// regardless of what the tenant had installed. This provider is what
/// [AppShell] now gates those destinations against.
final FutureProvider<Set<String>> installedAppSlugsProvider =
    FutureProvider<Set<String>>((Ref ref) async {
  // Re-fetches on tenant switch, same dependency `NotificationsController`
  // already watches for the same reason.
  ref.watch(activeTenantIdProvider);
  final List<String> slugs =
      await ref.watch(apiClientProvider).getStringList(ApiPaths.installedApps);
  return slugs.toSet();
});
