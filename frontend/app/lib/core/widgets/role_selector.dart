import 'package:flutter/material.dart';

import '../../features/auth/domain/auth_state.dart';
import '../design/theme.dart';
import '../design/tokens.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BBRadius.pill,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            label: 'Customer',
            isSelected: selectedRole == UserRole.customer,
            onTap: () => onChanged(UserRole.customer),
            colors: colors,
          ),
          _Tab(
            label: 'Barber',
            isSelected: selectedRole == UserRole.barber,
            onTap: () => onChanged(UserRole.barber),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final BBColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BBMotion.fast,
          curve: Curves.easeInOut,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? BBColors.brandPrimary : Colors.transparent,
            borderRadius: BBRadius.pill,
          ),
          child: Text(
            label,
            style: BBTypography.labelM.copyWith(
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
