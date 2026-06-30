import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/bb_button.dart';
import '../../auth/data/auth_provider.dart';
import '../dashboard/barber_provider.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class StaffMember {
  const StaffMember({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id; // ShopStaff.id
  final String userId;
  final String fullName;
  final String email;
  final String role; // 'OWNER' | 'RECEPTION' | 'BARBER'

  String get initials => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  factory StaffMember.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return StaffMember(
      id: j['id']?.toString() ?? '',
      userId: j['userId']?.toString() ?? '',
      fullName: user['fullName']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? '',
    );
  }
}

// ─── State ───────────────────────────────────────────────────────────────────

class ShopStaffState {
  const ShopStaffState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  final List<StaffMember> members;
  final bool isLoading;
  final String? error;

  ShopStaffState copyWith({
    List<StaffMember>? members,
    bool? isLoading,
    String? error,
  }) =>
      ShopStaffState(
        members: members ?? this.members,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ShopStaffNotifier
    extends AutoDisposeFamilyNotifier<ShopStaffState, String> {
  @override
  ShopStaffState build(String shopId) {
    _load();
    return const ShopStaffState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get<Map<String, dynamic>>(
        ApiEndpoints.shopStaff(arg),
      );
      final list = (data['staff'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StaffMember.fromJson)
          .toList();
      state = ShopStaffState(members: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> addByEmail(String email) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        ApiEndpoints.shopStaff(arg),
        body: {'email': email.trim()},
      );
      await _load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> remove(String staffId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete(ApiEndpoints.shopStaffMember(arg, staffId));
      state = state.copyWith(
        members: state.members.where((m) => m.id != staffId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => _load();
}

final shopStaffProvider = AutoDisposeNotifierProviderFamily<ShopStaffNotifier,
    ShopStaffState, String>(
  ShopStaffNotifier.new,
);

// ─── Screen ──────────────────────────────────────────────────────────────────

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final dashState = ref.watch(barberDashProvider);
    final shopId = dashState.profile?.shopId;
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.isOwner ?? false;

    if (shopId == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(title: const Text('Employees')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final staffState = ref.watch(shopStaffProvider(shopId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Employees',
          style: BBTypography.textTheme.titleLarge
              ?.copyWith(color: colors.text, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(AppIcons.personAdd, color: colors.text),
              onPressed: () => _showAddSheet(context, ref, shopId),
            ),
        ],
      ),
      body: staffState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : staffState.error != null && staffState.members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.warning,
                            size: 40, color: colors.textTertiary),
                        const SizedBox(height: BBSpacing.md),
                        Text(staffState.error!,
                            textAlign: TextAlign.center,
                            style: BBTypography.textTheme.bodyMedium
                                ?.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: BBSpacing.md),
                        TextButton(
                          onPressed: () =>
                              ref.read(shopStaffProvider(shopId).notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : staffState.members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.people,
                              size: 48, color: colors.textTertiary),
                          const SizedBox(height: BBSpacing.md),
                          Text('No staff members yet',
                              style: BBTypography.textTheme.titleMedium
                                  ?.copyWith(color: colors.textSecondary)),
                          if (isOwner) ...[
                            const SizedBox(height: BBSpacing.sm),
                            Text('Tap + to invite a team member',
                                style: BBTypography.textTheme.bodySmall
                                    ?.copyWith(color: colors.textTertiary)),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: BBColors.amber,
                      onRefresh: () =>
                          ref.read(shopStaffProvider(shopId).notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                        itemCount: staffState.members.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: BBSpacing.sm),
                        itemBuilder: (ctx, i) => _EmployeeCard(
                          member: staffState.members[i],
                          shopId: shopId,
                          canRemove: isOwner,
                        ),
                      ),
                    ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (_) => _AddEmployeeSheet(shopId: shopId),
    );
  }
}

// ─── Employee Card ────────────────────────────────────────────────────────────

class _EmployeeCard extends ConsumerWidget {
  const _EmployeeCard({
    required this.member,
    required this.shopId,
    required this.canRemove,
  });

  final StaffMember member;
  final String shopId;
  final bool canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;

    final roleColor = switch (member.role.toUpperCase()) {
      'OWNER' => BBColors.amber,
      'RECEPTION' => BBColors.info,
      _ => BBColors.success,
    };
    final roleLabel = switch (member.role.toUpperCase()) {
      'OWNER' => 'Owner',
      'RECEPTION' => 'Reception',
      'BARBER' => 'Barber',
      _ => member.role,
    };

    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BBColors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: BBTypography.textTheme.titleLarge?.copyWith(
                  color: BBColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  member.email,
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: BBSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BBRadius.full),
            ),
            child: Text(
              roleLabel,
              style: BBTypography.textTheme.labelSmall?.copyWith(
                color: roleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: BBSpacing.sm),
            GestureDetector(
              onTap: () => _confirmRemove(context, ref),
              child: Icon(AppIcons.close,
                  size: 18, color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove staff member?'),
        content: Text(
            'Remove ${member.fullName} from your shop? Their role will be reverted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('Remove', style: TextStyle(color: BBColors.error))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success =
        await ref.read(shopStaffProvider(shopId).notifier).remove(member.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? '${member.fullName} removed' : 'Failed to remove staff'),
        backgroundColor: success ? BBColors.success : BBColors.error,
      ),
    );
  }
}

// ─── Add Employee Sheet ───────────────────────────────────────────────────────

class _AddEmployeeSheet extends ConsumerStatefulWidget {
  const _AddEmployeeSheet({required this.shopId});
  final String shopId;

  @override
  ConsumerState<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<_AddEmployeeSheet> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

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
                'Add Staff Member',
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
          const SizedBox(height: BBSpacing.sm),
          Text(
            'Enter the email address of a BookBer user to add them as reception staff.',
            style: BBTypography.textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BBSpacing.base),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'staff@example.com',
              prefixIcon: const Icon(AppIcons.mail),
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: _loading ? 'Adding…' : 'Add Staff Member',
            icon: AppIcons.personAdd,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    final success = await ref
        .read(shopStaffProvider(widget.shopId).notifier)
        .addByEmail(email);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Staff member added successfully'
            : 'No BookBer account found with that email'),
        backgroundColor: success ? BBColors.success : BBColors.error,
      ),
    );
  }
}
