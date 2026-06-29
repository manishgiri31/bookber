import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  static const _employees = [
    ('Alex Silva', 'Senior Barber', true, 4.9, 142),
    ('Sam Khan', 'Barber', true, 4.7, 98),
    ('Mike Patel', 'Junior Barber', false, 4.5, 34),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.personAdd),
            onPressed: () => _showAddEmployee(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        itemCount: _employees.length,
        separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
        itemBuilder: (ctx, i) {
          final e = _employees[i];
          return _EmployeeCard(
            name: e.$1,
            role: e.$2,
            isAvailable: e.$3,
            rating: e.$4,
            completedJobs: e.$5,
          );
        },
      ),
    );
  }

  void _showAddEmployee(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (_) => const _AddEmployeeSheet(),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.name,
    required this.role,
    required this.isAvailable,
    required this.rating,
    required this.completedJobs,
  });
  final String name;
  final String role;
  final bool isAvailable;
  final double rating;
  final int completedJobs;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BBColors.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: BBTypography.textTheme.titleLarge?.copyWith(
                          color: BBColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? BBColors.success
                            : colors.textTertiary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: BBTypography.textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role,
                      style: BBTypography.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? BBColors.success.withValues(alpha: 0.1)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
                child: Text(
                  isAvailable ? 'On Duty' : 'Off',
                  style: BBTypography.textTheme.labelSmall?.copyWith(
                    color:
                        isAvailable ? BBColors.success : colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.md),
          Row(
            children: [
              _StatPill(
                  icon: AppIcons.starFill,
                  label: rating.toStringAsFixed(1),
                  color: BBColors.amber),
              const SizedBox(width: BBSpacing.sm),
              _StatPill(
                  icon: AppIcons.checkCircle,
                  label: '$completedJobs jobs',
                  color: BBColors.success),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon:
                    const Icon(AppIcons.edit, size: 14),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEmployeeSheet extends StatefulWidget {
  const _AddEmployeeSheet();

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'Barber';

  static const _roles = ['Senior Barber', 'Barber', 'Junior Barber', 'Receptionist'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: EdgeInsets.only(
        left: BBSpacing.pageHorizontal,
        right: BBSpacing.pageHorizontal,
        top: BBSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + BBSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add Employee',
                style: BBTypography.textTheme.headlineSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(AppIcons.close, color: colors.textTertiary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              labelText: 'Employee Email',
              hintText: 'barber@example.com',
              prefixIcon: const Icon(AppIcons.mail),
            ),
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'ROLE',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            items: _roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _selectedRole = v!),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: 'Send Invite',
            icon: AppIcons.send,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
