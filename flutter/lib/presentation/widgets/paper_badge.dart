import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PaperBadge extends StatelessWidget {
  final bool small;

  const PaperBadge({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: kWarningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: kWarningColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        'PAPER',
        style: TextStyle(
          color: kWarningColor,
          fontSize: small ? 8 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
