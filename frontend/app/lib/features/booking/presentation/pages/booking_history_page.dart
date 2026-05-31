import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../booking_controller.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/section_card.dart';

class BookingHistoryPage extends ConsumerWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(bookingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking history')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: history.when(
          data: (items) => ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = items[index];
              return SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(booking.barberName),
                  subtitle: Text('${booking.serviceNames.join(', ')} - ${booking.status}'),
                  trailing: Text('${booking.estimatedWaitMinutes}m'),
                ),
              );
            },
          ),
          loading: () => const Column(
            children: [
              LoadingSkeleton(height: 72),
              SizedBox(height: 12),
              LoadingSkeleton(height: 72),
            ],
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.read(bookingControllerProvider.notifier).refreshHistory(),
          ),
        ),
      ),
    );
  }
}
