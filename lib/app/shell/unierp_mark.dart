import 'package:flutter/material.dart';

/// Native counterpart of the canonical shield/U mark used by UniERP web shells.
class UniErpMark extends StatelessWidget {
  const UniErpMark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(
              Icons.shield_rounded,
              size: size,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: size * .38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}
