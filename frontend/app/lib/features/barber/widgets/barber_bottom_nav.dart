import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

class BarberBottomNav extends StatelessWidget {
  const BarberBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_outline, Icons.people_rounded, 'Queue'),
    (Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Schedule'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BBColors.bgSurface,
        border: Border(
          top: BorderSide(color: BBColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final i = e.key;
              final (outlinedIcon, filledIcon, label) = e.value;
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: BBMotion.fast,
                    curve: BBMotion.smooth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: isActive ? 1.1 : 1.0,
                          duration: BBMotion.fast,
                          child: Icon(
                            isActive ? filledIcon : outlinedIcon,
                            size: BBIconSize.md,
                            color: isActive
                                ? BBColors.brandPrimary
                                : BBColors.textDisabled,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: BBMotion.fast,
                          style: BBTypography.labelS.copyWith(
                            color: isActive
                                ? BBColors.brandPrimary
                                : BBColors.textDisabled,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
