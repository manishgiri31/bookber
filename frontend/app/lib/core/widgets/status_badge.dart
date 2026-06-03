import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusType { active, inactive, pending, warning, error }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType status;

  const StatusBadge({Key? key, required this.label, this.status = StatusType.active}) : super(key: key);

  Color _color(BuildContext context) {
    switch (status) {
      case StatusType.active:
        return AppColors.success;
      case StatusType.inactive:
        return AppColors.textTertiary;
      case StatusType.pending:
        return AppColors.warning;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color(context).withOpacity(0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _color(context))),
    );
  }
}
