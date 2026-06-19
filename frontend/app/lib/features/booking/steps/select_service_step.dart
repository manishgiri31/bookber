import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart' show Service;
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class SelectServiceStep extends ConsumerWidget {
  const SelectServiceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(bookingFormProvider);
    final servicesAsync = ref.watch(availableServicesProvider(formState.shopId));

    return Column(
      children: [
        const BookingStepIndicator(currentStep: 1),
        const SizedBox(height: BBSpacing.px24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
          child: Text(
            formState.shopName,
            style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: BBSpacing.px16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BBRadius.md,
            ),
            child: Row(
              children: [
                const SizedBox(width: BBSpacing.px16),
                Icon(Icons.search, size: BBIconSize.sm, color: colors.textSecondary),
                const SizedBox(width: BBSpacing.px12),
                Expanded(
                  child: TextField(
                    style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: BBTypography.bodyM.copyWith(color: colors.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: BBSpacing.px24),

        Expanded(
          child: servicesAsync.when(
            data: (services) {
              final groupedServices = _groupServicesByCategory(services);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
                itemCount: groupedServices.length,
                itemBuilder: (context, index) {
                  final category = groupedServices.keys.elementAt(index);
                  final categoryServices = groupedServices[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: BBSpacing.px12),
                      ...categoryServices.map((service) {
                        final isSelected = formState.selectedServiceIds.contains(service.id);
                        return _ServiceTile(
                          service: service,
                          isSelected: isSelected,
                          onTap: () {
                            ref.read(bookingFormProvider.notifier).toggleService(service);
                          },
                        );
                      }),
                      const SizedBox(height: BBSpacing.px24),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: BBColors.brandPrimary),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading services',
                style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(BBSpacing.px20),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border(top: BorderSide(color: colors.borderSubtle)),
          ),
          child: Column(
            children: [
              if (formState.selectedServiceIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BBSpacing.px16, vertical: BBSpacing.px12),
                  decoration: BoxDecoration(
                    color: BBColors.brandPrimaryDim,
                    borderRadius: BBRadius.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formState.selectedServiceIds.length} services',
                        style: BBTypography.labelM.copyWith(color: BBColors.brandPrimary),
                      ),
                      Text(
                        '₹${formState.totalPrice} · ~${formState.totalDuration} min',
                        style: BBTypography.labelM.copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              if (formState.selectedServiceIds.isNotEmpty) const SizedBox(height: BBSpacing.px16),
              SizedBox(
                width: double.infinity,
                height: BBTouchTarget.button,
                child: ElevatedButton(
                  onPressed: formState.selectedServiceIds.isNotEmpty
                      ? () => ref.read(bookingFormProvider.notifier).nextStep()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BBColors.brandPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.bgElevated,
                    disabledForegroundColor: colors.textDisabled,
                    shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
                    elevation: 0,
                  ),
                  child: Text('Continue', style: BBTypography.button),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, List<Service>> _groupServicesByCategory(List<Service> services) {
    final grouped = <String, List<Service>>{};
    for (final service in services) {
      grouped.putIfAbsent(service.category, () => []).add(service);
    }
    return grouped;
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: BBSpacing.px12),
        padding: const EdgeInsets.all(BBSpacing.px16),
        decoration: BoxDecoration(
          color: isSelected ? BBColors.brandPrimaryDim : colors.bgSurface,
          borderRadius: BBRadius.md,
          border: Border.all(
            color: isSelected ? BBColors.brandPrimary : colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: BBTypography.bodyL.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: BBSpacing.px4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                      const SizedBox(width: BBSpacing.px4),
                      Text(
                        '${service.duration} min',
                        style: BBTypography.bodyS.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '₹${service.price}',
                  style: BBTypography.headingS.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(width: BBSpacing.px12),
                if (isSelected)
                  const Icon(Icons.check_circle, color: BBColors.brandPrimary, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
