import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';

class CustomerNavBar extends ConsumerWidget {
  const CustomerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined,       Icons.home_rounded,            'Home'),
    (Icons.explore_outlined,    Icons.explore_rounded,         'Explore'),
    (Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Bookings'),
    (Icons.person_outline,      Icons.person_rounded,          'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 1),
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
                              : colors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: BBMotion.fast,
                        style: BBTypography.labelS.copyWith(
                          color: isActive
                              ? BBColors.brandPrimary
                              : colors.textDisabled,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(label),
                      ),
                    ],
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
