import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../booking_flow_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/section_card.dart';

class BookingConfirmationPage extends ConsumerWidget {
  const BookingConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bookingFlowControllerProvider);
    final controller = ref.read(bookingFlowControllerProvider.notifier);
    final barber = flow.selectedBarber;
    final selectedSlot = flow.selectedTimeSlot;
    final scheduledAt = flow.booking?.scheduledAt ?? selectedSlot;
    final totalDuration = controller.estimateServiceDuration();
    final totalPrice = flow.selectedServices.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    final completion = scheduledAt?.add(Duration(minutes: totalDuration));
    final arrivalLabel = scheduledAt != null
        ? _formatTime(scheduledAt)
        : 'Flexible';
    final completedLabel = completion != null ? _formatTime(completion) : '--';
    final barberReadyLabel = scheduledAt != null
        ? _formatTime(scheduledAt.subtract(const Duration(minutes: 8)))
        : '--';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                _StepBadge(label: '1', title: 'Barber'),
                const SizedBox(width: 8),
                _StepBadge(label: '2', title: 'Service'),
                const SizedBox(width: 8),
                _StepBadge(label: '3', title: 'Timing', active: true),
                const SizedBox(width: 8),
                _StepBadge(label: '4', title: 'Confirm'),
              ],
            ),
            const SizedBox(height: 22),
            if (flow.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ErrorView(
                  message: flow.errorMessage!,
                  onRetry: () => controller.createBooking(),
                ),
              ),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to book',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    barber?.name ?? 'No barber selected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arrival: $arrivalLabel • Completion: $completedLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KeyMetric(label: 'Queue', value: '#3'),
                      _KeyMetric(
                        label: 'Duration',
                        value: '$totalDuration min',
                      ),
                      _KeyMetric(label: 'Barber free', value: barberReadyLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...flow.selectedServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₹${service.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '₹${totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queue preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your position is estimated based on live availability and selected time.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: 0.6, minHeight: 8),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('Start soon'), Text('Optimal')],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: flow.isBooking
                  ? null
                  : () async {
                      await controller.createBooking();
                      final booking = ref
                          .read(bookingFlowControllerProvider)
                          .booking;
                      if (booking != null && context.mounted) {
                        context.go(
                          RoutePaths.queue.replaceAll(':bookingId', booking.id),
                        );
                      }
                    },
              child: flow.isBooking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm & track'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.label,
    required this.title,
    this.active = false,
  });

  final String label;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: active ? Colors.white : Colors.grey.shade400,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyMetric extends StatelessWidget {
  const _KeyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
