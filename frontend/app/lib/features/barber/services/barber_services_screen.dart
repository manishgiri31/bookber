import 'package:flutter/material.dart';
import '../../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../../../core/widgets/bb_button.dart';
import '../../../core/widgets/bb_snackbar.dart';
import '../../../core/widgets/bb_text_field.dart';

// ── Demo data ─────────────────────────────────────────────────────────────────

class _ServiceItem {
  _ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMin,
    required this.isActive,
  });
  final String id;
  final String name;
  final String category;
  double price;
  int durationMin;
  bool isActive;
}

final _servicesProvider =
    StateNotifierProvider.autoDispose<_ServicesNotifier, List<_ServiceItem>>(
        (_) => _ServicesNotifier());

class _ServicesNotifier extends StateNotifier<List<_ServiceItem>> {
  _ServicesNotifier()
      : super([
          _ServiceItem(
              id: '1',
              name: 'Classic Haircut',
              category: 'Haircut',
              price: 200,
              durationMin: 30,
              isActive: true),
          _ServiceItem(
              id: '2',
              name: 'Skin Fade',
              category: 'Haircut',
              price: 350,
              durationMin: 45,
              isActive: true),
          _ServiceItem(
              id: '3',
              name: 'Beard Trim',
              category: 'Beard',
              price: 150,
              durationMin: 20,
              isActive: true),
          _ServiceItem(
              id: '4',
              name: 'Full Beard Shave',
              category: 'Beard',
              price: 250,
              durationMin: 30,
              isActive: false),
          _ServiceItem(
              id: '5',
              name: 'Hair Wash',
              category: 'Treatment',
              price: 120,
              durationMin: 15,
              isActive: true),
          _ServiceItem(
              id: '6',
              name: 'Head Massage',
              category: 'Treatment',
              price: 200,
              durationMin: 20,
              isActive: true),
        ]);

  void toggle(String id) {
    state = [
      for (final s in state)
        if (s.id == id)
          _ServiceItem(
            id: s.id,
            name: s.name,
            category: s.category,
            price: s.price,
            durationMin: s.durationMin,
            isActive: !s.isActive,
          )
        else
          s
    ];
  }

  void add(_ServiceItem item) => state = [...state, item];

  void update(String id, double price, int duration) {
    state = [
      for (final s in state)
        if (s.id == id)
          _ServiceItem(
            id: s.id,
            name: s.name,
            category: s.category,
            price: price,
            durationMin: duration,
            isActive: s.isActive,
          )
        else
          s
    ];
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BarberServicesScreen extends ConsumerStatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  ConsumerState<BarberServicesScreen> createState() =>
      _BarberServicesScreenState();
}

class _BarberServicesScreenState extends ConsumerState<BarberServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _categories = ['All', 'Haircut', 'Beard', 'Treatment'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            onPressed: () => _showAddService(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: colors.text,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: BBColors.amber,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _categories.map((cat) {
          return _ServicesList(category: cat == 'All' ? null : cat);
        }).toList(),
      ),
    );
  }

  void _showAddService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (_) => const _AddServiceSheet(),
    );
  }
}

// ── Services List ─────────────────────────────────────────────────────────────

class _ServicesList extends ConsumerWidget {
  const _ServicesList({this.category});
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(_servicesProvider);
    final services = category == null
        ? all
        : all.where((s) => s.category == category).toList();

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.scissors,
                size: 48, color: context.bbColors.textTertiary),
            const SizedBox(height: BBSpacing.md),
            Text(
              'No services in this category',
              style: BBTypography.textTheme.bodyMedium?.copyWith(
                color: context.bbColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(BBSpacing.pageHorizontal),
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(height: BBSpacing.sm),
      itemBuilder: (ctx, i) => _ServiceCard(service: services[i]),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});
  final _ServiceItem service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.all(BBSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BBRadius.xl),
        border: Border.all(
          color: service.isActive
              ? colors.border
              : colors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: service.isActive
                      ? BBColors.amber.withValues(alpha: 0.12)
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(BBRadius.md),
                ),
                child: Icon(
                  AppIcons.scissors,
                  size: 20,
                  color:
                      service.isActive ? BBColors.amber : colors.textTertiary,
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: BBTypography.textTheme.titleSmall?.copyWith(
                        color: service.isActive
                            ? colors.text
                            : colors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      service.category,
                      style: BBTypography.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: service.isActive,
                onChanged: (_) =>
                    ref.read(_servicesProvider.notifier).toggle(service.id),
                activeTrackColor: BBColors.amber,
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.sm),
          Row(
            children: [
              _PriceDurationPill(
                icon: AppIcons.currencyRupee,
                label: '₹${service.price.toStringAsFixed(0)}',
              ),
              const SizedBox(width: BBSpacing.sm),
              _PriceDurationPill(
                icon: AppIcons.timer,
                label: '${service.durationMin} min',
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showEditSheet(context, service),
                icon: const Icon(AppIcons.edit, size: 14),
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

  void _showEditSheet(BuildContext context, _ServiceItem service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(BBRadius.xxl)),
      ),
      builder: (_) => _EditServiceSheet(service: service),
    );
  }
}

class _PriceDurationPill extends StatelessWidget {
  const _PriceDurationPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
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

// ── Add Service Sheet ─────────────────────────────────────────────────────────

class _AddServiceSheet extends ConsumerStatefulWidget {
  const _AddServiceSheet();

  @override
  ConsumerState<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends ConsumerState<_AddServiceSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _selectedCategory = 'Haircut';
  bool _saving = false;

  static const _cats = ['Haircut', 'Beard', 'Treatment', 'Color', 'Kids'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
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
                'Add Service',
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
          BBTextField(
            controller: _nameCtrl,
            label: 'Service Name',
            hint: 'e.g. Classic Haircut',
          ),
          const SizedBox(height: BBSpacing.md),
          Row(
            children: [
              Expanded(
                child: BBTextField(
                  controller: _priceCtrl,
                  label: 'Price (₹)',
                  hint: '200',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: BBTextField(
                  controller: _durationCtrl,
                  label: 'Duration (min)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.md),
          Text(
            'CATEGORY',
            style: BBTypography.textTheme.labelSmall?.copyWith(
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: BBSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: _cats
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: 'Add Service',
            icon: AppIcons.add,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      showBBSnackbar(context, message: 'Please enter a service name');
      return;
    }
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final duration = int.tryParse(_durationCtrl.text) ?? 30;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    ref.read(_servicesProvider.notifier).add(
          _ServiceItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameCtrl.text.trim(),
            category: _selectedCategory,
            price: price,
            durationMin: duration,
            isActive: true,
          ),
        );
    if (mounted) {
      Navigator.of(context).pop();
      showBBSnackbar(context,
          message: 'Service added!', isSuccess: true);
    }
  }
}

// ── Edit Service Sheet ────────────────────────────────────────────────────────

class _EditServiceSheet extends ConsumerStatefulWidget {
  const _EditServiceSheet({required this.service});
  final _ServiceItem service;

  @override
  ConsumerState<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends ConsumerState<_EditServiceSheet> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.service.price.toStringAsFixed(0));
    _durationCtrl =
        TextEditingController(text: widget.service.durationMin.toString());
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _durationCtrl.dispose();
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
              Expanded(
                child: Text(
                  widget.service.name,
                  style: BBTypography.textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.close, color: colors.textTertiary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.base),
          Row(
            children: [
              Expanded(
                child: BBTextField(
                  controller: _priceCtrl,
                  label: 'Price (₹)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: BBSpacing.md),
              Expanded(
                child: BBTextField(
                  controller: _durationCtrl,
                  label: 'Duration (min)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpacing.xl),
          BBButton(
            label: 'Save Changes',
            icon: AppIcons.check,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text) ?? widget.service.price;
    final duration =
        int.tryParse(_durationCtrl.text) ?? widget.service.durationMin;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    ref
        .read(_servicesProvider.notifier)
        .update(widget.service.id, price, duration);
    if (mounted) {
      Navigator.of(context).pop();
      showBBSnackbar(context, message: 'Updated!', isSuccess: true);
    }
  }
}
