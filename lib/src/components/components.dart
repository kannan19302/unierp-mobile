// Flutter Design System Components Parity (B19, B20, B21, B22)
// Generated for UniERP Mobile & Desktop

import 'package:flutter/material.dart';
import '../tokens/tokens.g.dart';

/// UniButton - Flutter implementation of Button primitive
class UniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Widget? icon;

  const UniButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? UniTokens.primary : UniTokens.bgSunken,
        foregroundColor: primary ? Colors.white : UniTokens.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniTokens.radiusMd),
          side: primary ? BorderSide.none : const BorderSide(color: UniTokens.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: UniTokens.spaceMd,
          vertical: UniTokens.spaceSm,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: UniTokens.spaceXs)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// UniBadge - Flutter implementation of Badge primitive
class UniBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const UniBadge({Key? key, required this.label, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = color ?? UniTokens.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(UniTokens.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: UniTokens.primary),
      ),
    );
  }
}

/// UniCard - Flutter implementation of Card primitive
class UniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const UniCard({Key? key, required this.child, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(UniTokens.spaceMd),
      decoration: BoxDecoration(
        color: UniTokens.bgElevated,
        border: Border.all(color: UniTokens.border),
        borderRadius: BorderRadius.circular(UniTokens.radiusLg),
      ),
      child: child,
    );
  }
}

/// UniTable - Flutter implementation of DataGrid / Table primitive
class UniTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const UniTable({Key? key, required this.headers, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: UniTokens.border),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: UniTokens.bgSunken),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.all(UniTokens.spaceSm),
                    child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ))
              .toList(),
        ),
        ...rows.map((row) => TableRow(
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.all(UniTokens.spaceSm),
                        child: Text(cell, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}

/// UniDesktopChrome - B20 Desktop Window Chrome & Native Layout
class UniDesktopChrome extends StatelessWidget {
  final String title;
  final Widget body;

  const UniDesktopChrome({Key? key, required this.title, required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: UniTokens.bgSunken,
        foregroundColor: UniTokens.text,
        elevation: 0,
      ),
      body: SafeArea(child: body),
    );
  }
}
