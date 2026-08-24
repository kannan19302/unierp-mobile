import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../app/shell/unierp_mark.dart';

/// Shown while [AuthController] restores a persisted session on cold start.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UniErpMark(size: Spacing.x12),
            SizedBox(height: Spacing.x6),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
