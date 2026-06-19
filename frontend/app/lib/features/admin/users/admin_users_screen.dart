import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _selectedTab = 'Customers';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_selectedTab.toLowerCase()));

    return Scaffold(
      backgroundColor: context.bbColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.bbColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Customers',
                    isSelected: _selectedTab == 'Customers',
                    onTap: () => setState(() => _selectedTab = 'Customers'),
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Barbers',
                    isSelected: _selectedTab == 'Barbers',
                    onTap: () => setState(() => _selectedTab = 'Barbers'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User list
            Expanded(
              child: usersAsync.when(
                data: (users) => _UserList(users: users),
                loading: () => Center(
                  child: CircularProgressIndicator(color: BBColors.brandPrimary),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Error loading users',
                    style: TextStyle(color: context.bbColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? BBColors.brandPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? BBColors.brandPrimary : const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? BBColors.brandPrimary : context.bbColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users});

  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserAdminTile(user: user);
      },
    );
  }
}

class _UserAdminTile extends ConsumerWidget {
  const _UserAdminTile({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusLabel;

    switch (user.status) {
      case UserStatus.active:
        statusColor = BBColors.success;
        statusLabel = 'Active';
        break;
      case UserStatus.suspended:
        statusColor = BBColors.error;
        statusLabel = 'Suspended';
        break;
      case UserStatus.flagged:
        statusColor = BBColors.warning;
        statusLabel = 'Flagged';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.bbColors.bgElevated,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.bbColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.bbColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_formatDate(user.joinDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: context.bbColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(Icons.more_vert, color: context.bbColors.textSecondary),
            onPressed: () async {
              final nextStatus = user.status == UserStatus.suspended ? 'active' : 'suspended';
              await ref.read(adminActionsProvider.notifier).updateUserStatus(user.id, nextStatus);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
