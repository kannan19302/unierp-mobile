import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// B20 — Desktop Surface Configuration
/// Manages desktop window chrome, menu bar, shortcuts, and density overrides.

enum DesktopDensity { comfortable, compact }

class DesktopSurfaceConfig extends ChangeNotifier {
  DesktopDensity _density = DesktopDensity.compact;

  DesktopDensity get density => _density;

  void setDensity(DesktopDensity newDensity) {
    _density = newDensity;
    notifyListeners();
  }
}

class DesktopMenuBar extends StatelessWidget {
  const DesktopMenuBar({
    super.key,
    required this.child,
    this.onNewRecord,
    this.onSave,
    this.onFind,
  });

  final Widget child;
  final VoidCallback? onNewRecord;
  final VoidCallback? onSave;
  final VoidCallback? onFind;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'File',
          menus: [
            if (onNewRecord != null)
              PlatformMenuItem(
                label: 'New Record',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                onSelected: onNewRecord,
              ),
            if (onSave != null)
              PlatformMenuItem(
                label: 'Save',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
                onSelected: onSave,
              ),
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            if (onFind != null)
              PlatformMenuItem(
                label: 'Find (Command Palette)',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyK, control: true),
                onSelected: onFind,
              ),
          ],
        ),
      ],
      child: child,
    );
  }
}
