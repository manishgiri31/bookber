import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../booking_flow_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/service_chip.dart';
import '../widgets/section_card.dart';

class ServicesSelectionPage extends ConsumerWidget {
  const ServicesSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bookingFlowControllerProvider);
    final controller = ref.read(bookingFlowControllerProvider.notifier);
    final totalPrice = flow.selectedServices.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    final totalDuration = flow.selectedServices.fold<int>(
      0,
      (sum, item) => sum + item.durationMin,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select services')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 2 • Service selection'),
                  const SizedBox(height: 8),
                  Text(
                    flow.selectedBarber == null
                        ? 'Pick a barber first'
                        : 'Booking with ${flow.selectedBarber!.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (flow.selectedBarber != null)
                    Text(
                      flow.selectedBarber!.bio,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (flow.isLoadingServices)
              const Column(
                children: [
                  LoadingSkeleton(height: 90),
                  SizedBox(height: 14),
                  LoadingSkeleton(height: 90),
                ],
              )
            else if (flow.errorMessage != null)
              ErrorView(
                message: flow.errorMessage!,
                onRetry: () => controller.loadServices(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your service',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: flow.availableServices
                        .map(
                          (service) => ServiceChip(
                            label:
                                '${service.name} • ₹${service.price.toStringAsFixed(0)}',
                            selected: flow.selectedServices.any(
                              (item) => item.id == service.id,
                            ),
                            onTap: () => controller.toggleService(service),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${flow.selectedServices.length} services • $totalDuration min',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    '₹${totalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: flow.selectedServices.isEmpty
                  ? null
                  : () => context.go(RoutePaths.timing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Choose time'),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
