import 'package:flutter/material.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';

class BBStatusChip extends StatelessWidget {
  const BBStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = BBColors.statusColor(status);
    final label = _label(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BBRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: BBTypography.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static String _label(String status) => switch (status.toUpperCase()) {
        'QUEUED' || 'WAITING' => 'QUEUED',
        'READY' => 'READY',
        'CALLED' => 'CALLED',
        'IN_SERVICE' => 'IN SERVICE',
        'COMPLETED' => 'DONE',
        'CANCELLED' => 'CANCELLED',
        'NO_SHOW' => 'NO SHOW',
        _ => status.toUpperCase(),
      };
}
