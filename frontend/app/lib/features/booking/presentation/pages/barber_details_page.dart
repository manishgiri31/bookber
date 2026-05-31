import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../booking_flow_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_card.dart';

class BarberDetailsPage extends ConsumerStatefulWidget {
  const BarberDetailsPage({super.key, required this.barberId});

  final String barberId;

  @override
  ConsumerState<BarberDetailsPage> createState() => _BarberDetailsPageState();
}

class _BarberDetailsPageState extends ConsumerState<BarberDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bookingFlowControllerProvider.notifier).loadServices());
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowControllerProvider);
    final controller = ref.read(bookingFlowControllerProvider.notifier);
    final barber = flow.selectedBarber;

    return Scaffold(
      appBar: AppBar(title: const Text('Barber details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: barber == null
            ? const Center(child: Text('No barber selected'))
            : ListView(
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 30, child: Text(barber.name.substring(0, 1))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(barber.name, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text('${barber.rating} star - ${barber.distanceKm} km away'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(barber.bio),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go(RoutePaths.services),
                          child: const Text('Select services'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Available services', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (flow.isLoadingServices)
                    const Column(
                      children: [
                        LoadingSkeleton(height: 72),
                        SizedBox(height: 12),
                        LoadingSkeleton(height: 72),
                      ],
                    )
                  else if (flow.errorMessage != null)
                    ErrorView(message: flow.errorMessage!, onRetry: () => controller.loadServices())
                  else
                    ...flow.availableServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SectionCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name),
                            subtitle: Text('${service.category} - ${service.durationMin} min'),
                            trailing: Text('Rs. ${service.price.toStringAsFixed(0)}'),
                            onTap: () {
                              controller.toggleService(service);
                              context.go(RoutePaths.services);
                            },
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
