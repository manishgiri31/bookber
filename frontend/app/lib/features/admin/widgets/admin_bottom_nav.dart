import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';

class AdminBottomNav extends ConsumerWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AdminNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Overview',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _AdminNavItem(
              icon: Icons.store_outlined,
              label: 'Shops',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _AdminNavItem(
              icon: Icons.people_outline,
              label: 'Users',
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _AdminNavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Bookings',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            _AdminNavItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              index: 4,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final adminAccent = const Color(0xFF8B5CF6); // Soft purple for admin

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? adminAccent : BookBerPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? adminAccent : BookBerPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
