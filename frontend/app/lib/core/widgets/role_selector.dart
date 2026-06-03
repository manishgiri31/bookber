import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/design_system.dart';
import '../../features/auth/domain/auth_state.dart';

class RoleSelector extends StatefulWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RoleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRole != widget.selectedRole) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: BookBerPalette.bgElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Animated background pill
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: widget.selectedRole == UserRole.customer ? 4 : null,
            right: widget.selectedRole == UserRole.barber ? 4 : null,
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Container(
                  width: (MediaQuery.of(context).size.width - 48) / 2 - 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BookBerPalette.primaryAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              },
            ),
          ),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(UserRole.customer),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      'Customer',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedRole == UserRole.customer
                            ? BookBerPalette.bgPrimary
                            : BookBerPalette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onChanged(UserRole.barber),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      'Barber',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedRole == UserRole.barber
                            ? BookBerPalette.bgPrimary
                            : BookBerPalette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
