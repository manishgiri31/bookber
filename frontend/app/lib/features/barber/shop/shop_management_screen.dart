import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_loading.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_text_field.dart';
import '../../shared/domain/shop_models.dart';
import 'shop_management_provider.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() =>
      _ShopManagementScreenState();
}

class _ShopManagementScreenState
    extends ConsumerState<ShopManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final state = ref.watch(shopManagementProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Manage Shop'),
        bottom: TabBar(
          controller: _tab,
          labelColor: BBColors.amber,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          labelStyle: BBTypography.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Schedule'),
            Tab(text: 'Amenities'),
            Tab(text: 'Gallery'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: state.isLoading
          ? const BBSkeletonShopManagement()
          : state.error != null && state.shop == null
              ? _ErrorView(
                  error: state.error!,
                  onRetry: () =>
                      ref.read(shopManagementProvider.notifier).load(),
                )
              : TabBarView(
                  controller: _tab,
                  children: [
                    _ServicesTab(shop: state.shop),
                    _ScheduleTab(shop: state.shop),
                    _AmenitiesTab(shop: state.shop),
                    _GalleryTab(shop: state.shop),
                    _InfoTab(shop: state.shop),
                  ],
                ),
    );
  }
}

// ─── Services Tab ─────────────────────────────────────────────────────────────

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab({required this.shop});
  final ShopDetail? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final services = shop?.services ?? [];
    final isSaving = ref.watch(shopManagementProvider.select((s) => s.isSaving));

    return Stack(
      children: [
        services.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.scissors,
                        size: 48, color: colors.textTertiary),
                    const SizedBox(height: BBSpacing.base),
                    Text(
                      'No services yet',
                      style: BBTypography.textTheme.titleMedium
                          ?.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: BBSpacing.xs),
                    Text(
                      'Add your first service to start accepting bookings',
                      style: BBTypography.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpacing.xl),
                    BBButton(
                      label: 'Add Service',
                      icon: AppIcons.add,
                      onPressed: () => _showServiceForm(context, ref, null),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
                children: [
                  ...services.map(
                    (svc) => _ServiceCard(
                      service: svc,
                      onEdit: () => _showServiceForm(context, ref, svc),
                      onDelete: () =>
                          _confirmDelete(context, ref, svc),
                    ),
                  ),
                  const SizedBox(height: BBSpacing.xxl),
                ],
              ),
        // FAB
        if (services.isNotEmpty)
          Positioned(
            bottom: BBSpacing.xl,
            right: BBSpacing.xl,
            child: FloatingActionButton.extended(
              onPressed: isSaving
                  ? null
                  : () => _showServiceForm(context, ref, null),
              backgroundColor: BBColors.amber,
              icon: const Icon(AppIcons.add, color: Colors.black),
              label: Text(
                'Add Service',
                style: BBTypography.textTheme.labelMedium
                    ?.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  void _showServiceForm(
      BuildContext context, WidgetRef ref, ServiceItem? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        existing: existing,
        shopId: ref.read(shopManagementProvider).shop?.id ?? '',
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ServiceItem svc) async {
    final colors = context.bbColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete Service',
            style: BBTypography.textTheme.titleMedium
                ?.copyWith(color: colors.text)),
        content: Text(
          'Remove "${svc.name}" from your shop? This cannot be undone.',
          style:
              BBTypography.textTheme.bodyMedium?.copyWith(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: BBColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final ok2 = await ref
          .read(shopManagementProvider.notifier)
          .deleteService(svc.id);
      if (context.mounted) {
        if (ok2) {
          showBBSnackbar(context, message: 'Service deleted', isSuccess: true);
        } else {
          showBBSnackbar(context, message: 'Failed to delete service', isError: true);
        }
      }
    }
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });
  final ServiceItem service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      margin: const EdgeInsets.only(bottom: BBSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.base),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BBColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BBRadius.md),
              ),
              child: Icon(
                _iconForCategory(service.category),
                size: 22,
                color: BBColors.amber,
              ),
            ),
            const SizedBox(width: BBSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: BBTypography.textTheme.titleSmall
                        ?.copyWith(color: colors.text, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        service.priceLabel,
                        style: BBTypography.textTheme.bodySmall?.copyWith(
                            color: BBColors.amber, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '  ·  ${service.durationLabel}',
                        style: BBTypography.textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                      Text(
                        '  ·  ${_labelForCategory(service.category)}',
                        style: BBTypography.textTheme.labelSmall
                            ?.copyWith(color: colors.textTertiary),
                      ),
                    ],
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: BBTypography.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(AppIcons.more,
                  color: colors.textSecondary, size: 20),
              color: colors.surface,
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(AppIcons.edit,
                        size: 16, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: colors.text)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Row(children: [
                    Icon(AppIcons.deleteIcon,
                        size: 16, color: BBColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: BBColors.error)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String cat) {
    return switch (cat.toUpperCase()) {
      'HAIRCUT' => AppIcons.scissors,
      'BEARD' => AppIcons.face,
      'COMBO' => AppIcons.spa,
      'SHAVE' => AppIcons.wash,
      'COLOR' => AppIcons.colorLens,
      _ => AppIcons.scissors,
    };
  }

  String _labelForCategory(String cat) => switch (cat.toUpperCase()) {
        'HAIRCUT' => 'Haircut',
        'BEARD' => 'Beard',
        'COMBO' => 'Combo',
        'SHAVE' => 'Shave',
        'COLOR' => 'Color',
        'TREATMENT' => 'Treatment',
        _ => cat,
      };
}

// ─── Service Form Sheet ────────────────────────────────────────────────────────

class _ServiceFormSheet extends ConsumerStatefulWidget {
  const _ServiceFormSheet({required this.existing, required this.shopId});
  final ServiceItem? existing;
  final String shopId;

  @override
  ConsumerState<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<_ServiceFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _category = 'HAIRCUT';
  bool _loading = false;
  String? _error;

  static const _categories = [
    ('HAIRCUT', 'Haircut'),
    ('BEARD', 'Beard'),
    ('COMBO', 'Combo'),
    ('SHAVE', 'Shave'),
    ('COLOR', 'Color'),
    ('TREATMENT', 'Treatment'),
    ('OTHER', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description ?? '';
      _priceCtrl.text = s.price.toStringAsFixed(0);
      _durationCtrl.text = s.durationMin.toString();
      _category = s.category.isNotEmpty ? s.category : 'HAIRCUT';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final duration = int.tryParse(_durationCtrl.text.trim());

    if (name.isEmpty || price == null || duration == null || duration < 5) {
      setState(() =>
          _error = 'Please fill in all required fields correctly.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final body = {
      'name': name,
      'description': _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
      'durationMinutes': duration,
      'price': price,
      'category': _category,
    };

    bool ok;
    if (widget.existing != null) {
      ok = await ref
          .read(shopManagementProvider.notifier)
          .updateService(widget.existing!.id, body);
    } else {
      ok = await ref
          .read(shopManagementProvider.notifier)
          .createService(body);
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showBBSnackbar(
          context,
          message: widget.existing != null
              ? 'Service updated'
              : 'Service added',
          isSuccess: true);
    } else {
      setState(() {
        _loading = false;
        _error = ref.read(shopManagementProvider).error ??
            'Something went wrong';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        BBSpacing.pageHorizontal,
        BBSpacing.base,
        BBSpacing.pageHorizontal,
        MediaQuery.of(context).viewInsets.bottom + BBSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BBSpacing.base),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(BBRadius.full),
                ),
              ),
            ),
            Text(
              isEdit ? 'Edit Service' : 'Add Service',
              style: BBTypography.textTheme.titleLarge
                  ?.copyWith(color: colors.text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: BBSpacing.xl),

            BBTextField(
              label: 'Service Name *',
              hint: 'e.g. Classic Haircut',
              controller: _nameCtrl,
              prefixIcon: AppIcons.labelOutline,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.md),

            BBTextField(
              label: 'Description',
              hint: 'Brief description',
              controller: _descCtrl,
              prefixIcon: AppIcons.description,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BBSpacing.md),

            Row(
              children: [
                Expanded(
                  child: BBTextField(
                    label: 'Price (₹) *',
                    hint: '250',
                    controller: _priceCtrl,
                    prefixIcon: AppIcons.currencyRupee,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: BBSpacing.sm),
                Expanded(
                  child: BBTextField(
                    label: 'Duration (min) *',
                    hint: '30',
                    controller: _durationCtrl,
                    prefixIcon: AppIcons.timer,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BBSpacing.md),

            Text(
              'Category',
              style: BBTypography.textTheme.labelMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: BBSpacing.sm),
            Wrap(
              spacing: BBSpacing.sm,
              runSpacing: BBSpacing.sm,
              children: _categories
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c.$2),
                      selected: _category == c.$1,
                      onSelected: (_) =>
                          setState(() => _category = c.$1),
                      selectedColor: BBColors.amber.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _category == c.$1
                            ? BBColors.amber
                            : colors.textSecondary,
                        fontWeight: _category == c.$1
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: _category == c.$1
                            ? BBColors.amber.withValues(alpha: 0.5)
                            : colors.border,
                      ),
                      backgroundColor: colors.surface,
                    ),
                  )
                  .toList(),
            ),

            if (_error != null) ...[
              const SizedBox(height: BBSpacing.md),
              Container(
                padding: const EdgeInsets.all(BBSpacing.md),
                decoration: BoxDecoration(
                  color: BBColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(BBRadius.md),
                  border: Border.all(
                      color: BBColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: BBColors.error),
                ),
              ),
            ],

            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: isEdit ? 'Save Changes' : 'Add Service',
              onPressed: _loading ? null : _submit,
              loading: _loading,
              icon: isEdit ? AppIcons.check : AppIcons.add,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Tab ─────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerStatefulWidget {
  const _ScheduleTab({required this.shop});
  final ShopDetail? shop;

  @override
  ConsumerState<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<_ScheduleTab> {
  final _openCtrl = TextEditingController();
  final _closeCtrl = TextEditingController();
  bool _acceptBookings = true;
  bool _acceptWalkIns = true;
  bool _loading = false;
  final Set<DateTime> _blockedDates = {};

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.shop == null) return;
    _openCtrl.text = widget.shop!.openingTime;
    _closeCtrl.text = widget.shop!.closingTime;
    _acceptBookings = widget.shop!.isAcceptingBookings;
    _acceptWalkIns = widget.shop!.isAcceptingWalkIns;
  }

  @override
  void didUpdateWidget(_ScheduleTab old) {
    super.didUpdateWidget(old);
    if (old.shop != widget.shop) _sync();
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    _closeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.firstOrNull ?? '9') ?? 9,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        ctrl.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final ok = await ref.read(shopManagementProvider.notifier).updateShopInfo({
      'openingTime': _openCtrl.text,
      'closingTime': _closeCtrl.text,
      'isAcceptingBookings': _acceptBookings,
      'isAcceptingWalkIns': _acceptWalkIns,
    });
    if (mounted) {
      setState(() => _loading = false);
      showBBSnackbar(
          context,
          message: ok ? 'Schedule updated' : 'Failed to update schedule',
          isError: !ok,
          isSuccess: ok);
    }
  }

  Future<void> _addHoliday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _blockedDates
          .add(DateTime(picked.year, picked.month, picked.day)));
    }
  }

  void _removeDate(DateTime d) => setState(() => _blockedDates.remove(d));

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        _SectionHeader(
            icon: AppIcons.accessTime, title: 'Opening Hours'),
        const SizedBox(height: BBSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Opens at',
                ctrl: _openCtrl,
                onTap: () => _pickTime(_openCtrl),
              ),
            ),
            const SizedBox(width: BBSpacing.sm),
            Expanded(
              child: _TimeField(
                label: 'Closes at',
                ctrl: _closeCtrl,
                onTap: () => _pickTime(_closeCtrl),
              ),
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.xl),

        _SectionHeader(
            icon: AppIcons.toggleOn, title: 'Availability'),
        const SizedBox(height: BBSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ToggleRow(
                icon: AppIcons.calendar,
                title: 'Accept Bookings',
                subtitle: 'Allow customers to book in advance',
                value: _acceptBookings,
                onChanged: (v) => setState(() => _acceptBookings = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.walk,
                title: 'Accept Walk-ins',
                subtitle: 'Allow walk-in customers to join queue',
                value: _acceptWalkIns,
                onChanged: (v) => setState(() => _acceptWalkIns = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: BBSpacing.xl),
        _SectionHeader(
            icon: AppIcons.eventBusy, title: 'Holidays & Closed Days'),
        const SizedBox(height: BBSpacing.md),
        if (_blockedDates.isEmpty)
          Container(
            padding: const EdgeInsets.all(BBSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(BBRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'No holidays added. Mark days when your shop will be closed.',
              style: BBTypography.textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BBRadius.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: () {
                final dates = _blockedDates.toList()..sort();
                final widgets = <Widget>[];
                for (var i = 0; i < dates.length; i++) {
                  widgets.add(_HolidayRow(
                    label: _formatDate(dates[i]),
                    onRemove: () => _removeDate(dates[i]),
                  ));
                  if (i < dates.length - 1) {
                    widgets.add(
                        Divider(color: colors.border, height: 1, indent: 52));
                  }
                }
                return widgets;
              }(),
            ),
          ),
        const SizedBox(height: BBSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(AppIcons.addCircle, size: 18),
            label: const Text('Add Holiday'),
            style: TextButton.styleFrom(foregroundColor: BBColors.amber),
            onPressed: _addHoliday,
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        BBButton(
          label: 'Save Schedule',
          onPressed: _loading ? null : _save,
          loading: _loading,
          icon: AppIcons.save,
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField(
      {required this.label, required this.ctrl, required this.onTap});
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.md, vertical: BBSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(BBRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: BBTypography.textTheme.labelSmall
                    ?.copyWith(color: colors.textTertiary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(AppIcons.accessTime,
                    size: 16, color: BBColors.amber),
                const SizedBox(width: 6),
                Text(
                  ctrl.text.isEmpty ? '--:--' : ctrl.text,
                  style: BBTypography.textTheme.titleSmall
                      ?.copyWith(color: colors.text, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base, vertical: BBSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: BBTypography.textTheme.bodyMedium
                        ?.copyWith(color: colors.text)),
                Text(subtitle,
                    style: BBTypography.textTheme.labelSmall
                        ?.copyWith(color: colors.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: BBColors.amber,
            activeTrackColor: BBColors.amber.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base, vertical: BBSpacing.sm),
      child: Row(
        children: [
          Icon(AppIcons.eventBusy, size: 18, color: BBColors.error),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Text(label,
                style: BBTypography.textTheme.bodyMedium
                    ?.copyWith(color: colors.text)),
          ),
          IconButton(
            icon: Icon(AppIcons.close, size: 16, color: colors.textTertiary),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Amenities Tab ────────────────────────────────────────────────────────────

class _AmenitiesTab extends StatefulWidget {
  const _AmenitiesTab({required this.shop});
  final ShopDetail? shop;

  @override
  State<_AmenitiesTab> createState() => _AmenitiesTabState();
}

class _AmenitiesTabState extends State<_AmenitiesTab> {
  bool _wifi = false;
  bool _parking = false;
  bool _ac = true;
  bool _water = true;
  bool _cardPayment = true;
  bool _upi = true;
  bool _kidsChairs = false;
  bool _wheelchair = false;
  bool _saving = false;

  Future<void> _saveAmenities() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    showBBSnackbar(context, message: 'Amenities saved', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        _SectionHeader(
            icon: AppIcons.localConvenienceStore, title: 'Facilities'),
        const SizedBox(height: BBSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ToggleRow(
                icon: AppIcons.wifi,
                title: 'Free WiFi',
                subtitle: 'Complimentary internet access',
                value: _wifi,
                onChanged: (v) => setState(() => _wifi = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.parking,
                title: 'Parking',
                subtitle: 'Free or paid parking available',
                value: _parking,
                onChanged: (v) => setState(() => _parking = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.acUnit,
                title: 'Air Conditioning',
                subtitle: 'Temperature-controlled environment',
                value: _ac,
                onChanged: (v) => setState(() => _ac = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.waterDrop,
                title: 'Drinking Water',
                subtitle: 'Complimentary water for customers',
                value: _water,
                onChanged: (v) => setState(() => _water = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        _SectionHeader(
            icon: AppIcons.payment, title: 'Payment Methods'),
        const SizedBox(height: BBSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ToggleRow(
                icon: AppIcons.payment,
                title: 'Card Payment',
                subtitle: 'Accept debit & credit cards',
                value: _cardPayment,
                onChanged: (v) => setState(() => _cardPayment = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.qrCode,
                title: 'UPI Payment',
                subtitle: 'GPay, PhonePe, Paytm & more',
                value: _upi,
                onChanged: (v) => setState(() => _upi = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        _SectionHeader(
            icon: AppIcons.accessible, title: 'Accessibility'),
        const SizedBox(height: BBSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _ToggleRow(
                icon: AppIcons.childFriendly,
                title: 'Kids Chairs',
                subtitle: 'Special chairs for young children',
                value: _kidsChairs,
                onChanged: (v) => setState(() => _kidsChairs = v),
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _ToggleRow(
                icon: AppIcons.accessible,
                title: 'Wheelchair Access',
                subtitle: 'Accessible entrance and facilities',
                value: _wheelchair,
                onChanged: (v) => setState(() => _wheelchair = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xl),
        BBButton(
          label: 'Save Amenities',
          icon: AppIcons.save,
          loading: _saving,
          onPressed: _saving ? null : _saveAmenities,
        ),
        const SizedBox(height: BBSpacing.xxl),
      ],
    );
  }
}

// ─── Gallery Tab ──────────────────────────────────────────────────────────────

class _GalleryTab extends StatefulWidget {
  const _GalleryTab({required this.shop});
  final ShopDetail? shop;

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<_GalleryTab> {
  int _photoCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Shop Photos',
                style: BBTypography.textTheme.titleMedium?.copyWith(
                    color: colors.text, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              icon:
                  const Icon(AppIcons.addPhoto, size: 18),
              label: const Text('Add Photo'),
              style: TextButton.styleFrom(foregroundColor: BBColors.amber),
              onPressed: () {
                setState(() => _photoCount++);
                showBBSnackbar(context,
                    message: 'Photo upload coming soon');
              },
            ),
          ],
        ),
        const SizedBox(height: BBSpacing.xs),
        Text(
          'Show customers what your shop looks like.',
          style: BBTypography.textTheme.bodySmall
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BBSpacing.base),
        if (_photoCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BBSpacing.xl),
            child: Column(
              children: [
                Icon(AppIcons.camera,
                    size: 56, color: colors.textTertiary),
                const SizedBox(height: BBSpacing.sm),
                Text(
                  'No photos yet',
                  style: BBTypography.textTheme.titleSmall
                      ?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: BBSpacing.xs),
                Text(
                  'Add photos to attract more customers',
                  style: BBTypography.textTheme.bodySmall
                      ?.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photoCount,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(BBRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(AppIcons.image,
                        size: 32, color: colors.textTertiary),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (_photoCount > 0) _photoCount--;
                      }),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: BBColors.error.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(AppIcons.close,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: BBSpacing.base),
        Container(
          padding: const EdgeInsets.all(BBSpacing.md),
          decoration: BoxDecoration(
            color: BBColors.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(BBRadius.md),
            border: Border.all(color: BBColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.info,
                  size: 16, color: BBColors.info),
              const SizedBox(width: BBSpacing.sm),
              Expanded(
                child: Text(
                  'Shops with photos get 3× more bookings.',
                  style: BBTypography.textTheme.labelSmall
                      ?.copyWith(color: BBColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BBSpacing.xxl),
      ],
    );
  }
}

// ─── Info Tab ─────────────────────────────────────────────────────────────────

class _InfoTab extends ConsumerStatefulWidget {
  const _InfoTab({required this.shop});
  final ShopDetail? shop;

  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.shop == null) return;
    _nameCtrl.text = widget.shop!.name;
    _descCtrl.text = widget.shop!.description;
    _phoneCtrl.text = widget.shop!.phone;
    _addressCtrl.text = widget.shop!.address;
  }

  @override
  void didUpdateWidget(_InfoTab old) {
    super.didUpdateWidget(old);
    if (old.shop != widget.shop) _sync();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final ok = await ref.read(shopManagementProvider.notifier).updateShopInfo({
      'name': name,
      'description': _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
      'phone': _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : null,
      'address': _addressCtrl.text.trim().isNotEmpty
          ? _addressCtrl.text.trim()
          : null,
    });
    if (mounted) {
      setState(() => _loading = false);
      showBBSnackbar(
          context,
          message: ok ? 'Shop info updated' : 'Failed to update',
          isError: !ok,
          isSuccess: ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    if (widget.shop == null) {
      return Center(
          child: Text('No shop info', style: TextStyle(color: colors.text)));
    }

    return ListView(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      children: [
        _SectionHeader(icon: AppIcons.store, title: 'Shop Details'),
        const SizedBox(height: BBSpacing.md),

        BBTextField(
          label: 'Shop Name *',
          hint: 'Your shop name',
          controller: _nameCtrl,
          prefixIcon: AppIcons.store,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: BBSpacing.md),
        BBTextField(
          label: 'Description',
          hint: 'Tell customers about your shop',
          controller: _descCtrl,
          prefixIcon: AppIcons.description,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: BBSpacing.md),
        BBTextField(
          label: 'Phone',
          hint: '+91 98765 43210',
          controller: _phoneCtrl,
          prefixIcon: AppIcons.phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: BBSpacing.md),
        BBTextField(
          label: 'Address',
          hint: 'Street address',
          controller: _addressCtrl,
          prefixIcon: AppIcons.locationOn,
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: BBSpacing.xl),
        _SectionHeader(icon: AppIcons.info, title: 'Shop Stats'),
        const SizedBox(height: BBSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(BBRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Total Chairs',
                value: widget.shop!.chairs.length.toString(),
                icon: AppIcons.chair,
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _InfoRow(
                label: 'BookBer Reserved',
                value: widget.shop!.chairs
                    .where((c) => c.reservedForBookBer)
                    .length
                    .toString(),
                icon: AppIcons.bookmark,
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _InfoRow(
                label: 'City',
                value: widget.shop!.city,
                icon: AppIcons.locationCity,
              ),
              Divider(color: colors.border, height: 1, indent: 52),
              _InfoRow(
                label: 'State',
                value: widget.shop!.state,
                icon: AppIcons.map,
              ),
            ],
          ),
        ),

        const SizedBox(height: BBSpacing.xl),
        BBButton(
          label: 'Save Changes',
          onPressed: _loading ? null : _save,
          loading: _loading,
          icon: AppIcons.save,
        ),
        const SizedBox(height: BBSpacing.xxl),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: BBSpacing.base, vertical: BBSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: BBSpacing.md),
          Expanded(
            child: Text(label,
                style: BBTypography.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary)),
          ),
          Text(value,
              style: BBTypography.textTheme.bodyMedium
                  ?.copyWith(color: colors.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Row(
      children: [
        Icon(icon, size: 18, color: BBColors.amber),
        const SizedBox(width: BBSpacing.sm),
        Text(
          title.toUpperCase(),
          style: BBTypography.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error,
                size: 48, color: BBColors.error),
            const SizedBox(height: BBSpacing.base),
            Text('Could not load shop',
                style: BBTypography.textTheme.titleMedium
                    ?.copyWith(color: colors.text)),
            const SizedBox(height: BBSpacing.xs),
            Text(error,
                style: BBTypography.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: BBSpacing.xl),
            BBButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
