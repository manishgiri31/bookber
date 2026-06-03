import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';

class CustomerNavBar extends ConsumerStatefulWidget {
  const CustomerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  ConsumerState<CustomerNavBar> createState() => _CustomerNavBarState();
}

class _CustomerNavBarState extends ConsumerState<CustomerNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        border: Border(
          top: BorderSide(
            color: const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.explore_outlined,
                label: 'Explore',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Bookings',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isActive ? 1.0 : 1.0,
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isActive ? 1.2 : 1.0,
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive
                      ? BookBerPalette.primaryAccent
                      : BookBerPalette.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BookBerPalette.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? BookBerPalette.primaryAccent
                      : BookBerPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
