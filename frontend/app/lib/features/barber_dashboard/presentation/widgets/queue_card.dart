import 'package:flutter/material.dart';

import '../../domain/barber_dashboard_models.dart';

class QueueCard extends StatelessWidget {
  const QueueCard({
    super.key,
    required this.customer,
    required this.onReady,
    required this.onStart,
  });

  final QueueCustomer customer;
  final VoidCallback onReady;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
                Text('#${customer.position}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('${customer.serviceName} - ${customer.waitMinutes} min - ${customer.status}'),
            const SizedBox(height: 4),
            Text(customer.walkIn ? 'Walk-in' : 'Booked customer'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(onPressed: onReady, child: const Text('Ready')),
                FilledButton.tonal(onPressed: onStart, child: const Text('Start service')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
