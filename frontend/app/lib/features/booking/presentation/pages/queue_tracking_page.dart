import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/bookber_models.dart';
import '../../../../core/realtime/socket_providers.dart';
import '../../../queue/presentation/queue_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/live_eta_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_card.dart';

class QueueTrackingPage extends ConsumerStatefulWidget {
  const QueueTrackingPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<QueueTrackingPage> createState() => _QueueTrackingPageState();
}

class _QueueTrackingPageState extends ConsumerState<QueueTrackingPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(queueControllerProvider.notifier)
          .loadQueue(widget.bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueControllerProvider);
    ref.listen(socketEventsProvider, (_, next) {
      next.whenData((event) {
        if (event['event'] == 'queue.updated') {
          ref
              .read(queueControllerProvider.notifier)
              .applySocketUpdate(
                QueueStateModel(
                  bookingId: widget.bookingId,
                  position: 2,
                  etaMinutes: 18,
                  status: 'APPROACHING',
                  chairLabel: 'Chair 2',
                ),
              );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Queue tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: queueState.when(
          data: (data) => ListView(
            children: [
              LiveEtaCard(
                minutes: data.etaMinutes,
                position: data.position,
                chairLabel: data.chairLabel,
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operational status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.status,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your appointment is being queued in real time. Track the barber’s next free chair and estimated start window.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    _QueueProgressBar(position: data.position),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Column(
            children: [
              LoadingSkeleton(height: 140),
              SizedBox(height: 16),
              LoadingSkeleton(height: 120),
            ],
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref
                .read(queueControllerProvider.notifier)
                .loadQueue(widget.bookingId),
          ),
        ),
      ),
    );
  }
}

class _QueueProgressBar extends StatelessWidget {
  const _QueueProgressBar({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final progress = (position / 5).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current place in line',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '#$position',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          progress >= 1
              ? 'Almost there'
              : '${(progress * 100).round()}% through the queue',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
