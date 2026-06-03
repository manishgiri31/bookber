import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart' show Service;
import '../widgets/booking_step_indicator.dart';
import '../providers/booking_form_provider.dart';

class SelectServiceStep extends ConsumerWidget {
  const SelectServiceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(bookingFormProvider);
    final servicesAsync = ref.watch(availableServicesProvider(formState.shopId));

    return Column(
      children: [
        // Step indicator
        const BookingStepIndicator(currentStep: 1),
        const SizedBox(height: 24),

        // Shop name header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            formState.shopName,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: BookBerPalette.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: BookBerPalette.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  Icons.search,
                  size: 20,
                  color: BookBerPalette.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: BookBerPalette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Services list
        Expanded(
          child: servicesAsync.when(
            data: (services) {
              final groupedServices = _groupServicesByCategory(services);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groupedServices.length,
                itemBuilder: (context, index) {
                  final category = groupedServices.keys.elementAt(index);
                  final categoryServices = groupedServices[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Service tiles
                      ...categoryServices.map((service) {
                        final isSelected = formState.selectedServiceIds.contains(service.id);
                        return _ServiceTile(
                          service: service,
                          isSelected: isSelected,
                          onTap: () {
                            ref.read(bookingFormProvider.notifier).toggleService(service);
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading services',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: BookBerPalette.textSecondary,
                ),
              ),
            ),
          ),
        ),

        // Bottom section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BookBerPalette.bgSurface,
            border: Border(
              top: BorderSide(
                color: const Color(0x0FFFFFFF),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Selected summary
              if (formState.selectedServiceIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: BookBerPalette.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formState.selectedServiceIds.length} services',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.primaryAccent,
                        ),
                      ),
                      Text(
                        '₹${formState.totalPrice} · ~${formState.totalDuration} min',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (formState.selectedServiceIds.isNotEmpty) const SizedBox(height: 16),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: formState.selectedServiceIds.isNotEmpty
                      ? () => ref.read(bookingFormProvider.notifier).nextStep()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BookBerPalette.primaryAccent,
                    foregroundColor: BookBerPalette.bgPrimary,
                    disabledBackgroundColor: BookBerPalette.bgElevated,
                    disabledForegroundColor: BookBerPalette.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? BookBerPalette.primaryAccent.withValues(alpha: 0.08)
              : BookBerPalette.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BookBerPalette.primaryAccent
                : const Color(0x0FFFFFFF),
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
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: BookBerPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${service.duration} min',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: BookBerPalette.primaryAccent,
                    size: 24,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
