import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/breakpoints.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import 'entitlement_provider.dart';
import '../theme/theme_mode_provider.dart';
import '../../core/config/env.dart';
import 'unierp_mark.dart';

/// Shell wrapping every authenticated route. Same [navigationShell] and
/// destination set on every platform — only the chrome changes: bottom nav
/// on phone width, a persistent sidebar (`NavigationRail`) from tablet width
/// up.
///
/// On phone the bottom nav scrolls horizontally for the extra destinations;
/// on tablet/desktop the sidebar shows all modules vertically.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  PreferredSizeWidget _appBar(BuildContext context, WidgetRef ref) => AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UniErpMark(size: 28),
            SizedBox(width: 8),
            Text('UniERP'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle light or dark theme',
            onPressed: () {
              final Brightness brightness = Theme.of(context).brightness;
              ref.read(themeModeProvider.notifier).state =
                  brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Account Center',
            onPressed: () => launchUrl(
              Uri.parse('${Env.idpOrigin}/oidc/account'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      );

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _Destination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
      slug: 'inventory',
    ),
    _Destination(
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      label: 'Sales',
      slug: 'sales',
    ),
    _Destination(
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
      label: 'Finance',
      slug: 'finance',
    ),
    _Destination(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'People',
      slug: 'hr',
    ),
    _Destination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Alerts',
    ),
    _Destination(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
      label: 'Supply Chain',
      slug: 'supply-chain',
    ),
    _Destination(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'POS',
      slug: 'pos',
    ),
    _Destination(
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      label: 'Manufacturing',
      slug: 'manufacturing',
    ),
    _Destination(
      icon: Icons.work_outline,
      selectedIcon: Icons.work,
      label: 'Projects',
      slug: 'projects',
    ),
    _Destination(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Documents',
      slug: 'drive',
    ),
    _Destination(
      icon: Icons.alt_route_outlined,
      selectedIcon: Icons.alt_route,
      label: 'Workflow',
    ),
    // ── Analytics ────────────────────────────────────────────────────
    _Destination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Analytics',
      slug: 'analytics',
    ),
    // ── AI ───────────────────────────────────────────────────────────
    _Destination(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'AI',
      slug: 'ai',
    ),
    // ── Builder ──────────────────────────────────────────────────────
    _Destination(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      label: 'Builder',
      slug: 'builder',
    ),
    // ── Communication ────────────────────────────────────────────────
    _Destination(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      label: 'Chat',
      slug: 'communication',
    ),
    // ── E-Commerce ───────────────────────────────────────────────────
    _Destination(
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      label: 'E-Commerce',
      slug: 'ecommerce',
    ),
    // ── Admin ────────────────────────────────────────────────────────
    _Destination(
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      label: 'Admin',
    ),
    // ── SaaS ─────────────────────────────────────────────────────────
    _Destination(
      icon: Icons.cloud_outlined,
      selectedIcon: Icons.cloud,
      label: 'SaaS',
    ),
    // ── Healthcare ───────────────────────────────────────────────────
    // Not gated: "healthcare" is not among the backend's known industry
    // bundle slugs (only education/real-estate/field-service are), so there
    // is nothing to check entitlement against yet — left ungated rather than
    // hidden by an entitlement check that can never be satisfied.
    _Destination(
      icon: Icons.local_hospital_outlined,
      selectedIcon: Icons.local_hospital,
      label: 'Health',
    ),
    // ── Education ────────────────────────────────────────────────────
    _Destination(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      label: 'Education',
      slug: 'education',
    ),
    // ── Field Service ────────────────────────────────────────────────
    _Destination(
      icon: Icons.build_circle_outlined,
      selectedIcon: Icons.build_circle,
      label: 'Field Svc',
      slug: 'field-service',
    ),
    // ── Real Estate ──────────────────────────────────────────────────
    _Destination(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'Real Estate',
      slug: 'real-estate',
    ),
    // ── Service Management ───────────────────────────────────────────
    _Destination(
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
      label: 'Services',
    ),
  ];

  /// `null` while the entitlement fetch is in flight or has failed — treated
  /// as "don't block yet" rather than "block everything", since this nav
  /// gate is a UX convenience, not the access-control boundary. The route
  /// guards and the API's own entitlement checks are what actually enforce
  /// access; this only keeps someone from tapping into a module their tenant
  /// never installed and hitting a raw 403 or empty screen instead.
  void _onSelect(
    BuildContext context,
    int index,
    Set<String>? entitledSlugs,
  ) {
    final _Destination destination = _destinations[index];
    if (entitledSlugs != null &&
        destination.slug != null &&
        !entitledSlugs.contains(destination.slug)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${destination.label} is not installed for your organisation.',
          ),
        ),
      );
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(unreadNotificationCountProvider);
    final Set<String>? entitledSlugs =
        ref.watch(installedAppSlugsProvider).valueOrNull;

    return isDesktopShell(context)
        ? _DesktopShell(
            navigationShell: navigationShell,
            unread: unread,
            onSelect: (int index) => _onSelect(context, index, entitledSlugs),
            destinations: _destinations,
            entitledSlugs: entitledSlugs,
            appBar: _appBar(context, ref),
          )
        : _MobileShell(
            navigationShell: navigationShell,
            unread: unread,
            onSelect: (int index) => _onSelect(context, index, entitledSlugs),
            destinations: _destinations,
            entitledSlugs: entitledSlugs,
            appBar: _appBar(context, ref),
          );
  }
}

/// Whether a destination should render at full strength. `null` (loading /
/// unknown) and kernel destinations (`slug == null`) both read as entitled —
/// see [AppShell._onSelect] for why "unknown" fails open here.
bool _isEntitled(_Destination d, Set<String>? entitledSlugs) =>
    entitledSlugs == null || d.slug == null || entitledSlugs.contains(d.slug);

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.navigationShell,
    required this.unread,
    required this.onSelect,
    required this.destinations,
    required this.entitledSlugs,
    required this.appBar,
  });

  final StatefulNavigationShell navigationShell;
  final int unread;
  final ValueChanged<int> onSelect;
  final List<_Destination> destinations;
  final Set<String>? entitledSlugs;
  final PreferredSizeWidget appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: navigationShell,
      bottomNavigationBar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: onSelect,
          height: 64,
          destinations: <Widget>[
            for (final _Destination d in destinations)
              NavigationDestination(
                icon: Opacity(
                  opacity: _isEntitled(d, entitledSlugs) ? 1 : 0.35,
                  child: d.withUnreadBadge(unread),
                ),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.navigationShell,
    required this.unread,
    required this.onSelect,
    required this.destinations,
    required this.entitledSlugs,
    required this.appBar,
  });

  final StatefulNavigationShell navigationShell;
  final int unread;
  final ValueChanged<int> onSelect;
  final List<_Destination> destinations;
  final Set<String>? entitledSlugs;
  final PreferredSizeWidget appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: <Widget>[
          // NavigationRail lays its destinations out in a fixed-height Column
          // with no built-in scrolling, so once there are more modules than
          // fit the window height it overflows (RenderFlex) instead of
          // scrolling. Wrapping it in a scroll view that's forced to at least
          // fill the available height keeps the rail full-height on tall
          // windows while letting it scroll on short ones.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: onSelect,
                      labelType: NavigationRailLabelType.all,
                      minExtendedWidth: 80,
                      destinations: <NavigationRailDestination>[
                        for (final _Destination d in destinations)
                          NavigationRailDestination(
                            icon: Opacity(
                              opacity: _isEntitled(d, entitledSlugs) ? 1 : 0.35,
                              child: d.withUnreadBadge(unread),
                            ),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.slug,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// The module slug this destination gates on (matches
  /// `api/src/common/module-tiers.ts`'s `GATED_MODULES`/industry-bundle
  /// slugs). `null` means kernel or otherwise ungated — always shown.
  final String? slug;

  Widget withUnreadBadge(int unread) {
    if (label != 'Alerts') return Icon(icon);
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: Icon(icon),
    );
  }
}
