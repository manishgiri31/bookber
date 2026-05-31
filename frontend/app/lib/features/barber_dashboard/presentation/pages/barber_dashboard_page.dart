import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/barber_dashboard_models.dart';
import '../barber_dashboard_controller.dart';
import '../widgets/dashboard_section_card.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/metric_tile.dart';
import '../widgets/queue_card.dart';

class BarberDashboardPage extends ConsumerStatefulWidget {
  const BarberDashboardPage({super.key});

  @override
  ConsumerState<BarberDashboardPage> createState() => _BarberDashboardPageState();
}

class _BarberDashboardPageState extends ConsumerState<BarberDashboardPage> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(barberDashboardControllerProvider);
    final controller = ref.read(barberDashboardControllerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final state = dashboard.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber dashboard'),
        actions: [
          if (state != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Switch.adaptive(
                  value: state.isAvailable,
                  onChanged: (_) => controller.toggleAvailability(),
                ),
              ),
            ),
        ],
      ),
      body: dashboard.when(
        data: (data) {
          final content = _buildSection(context, data, controller);
          if (!wide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            );
          }

          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => setState(() => selectedIndex = index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Overview'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.queue_outlined),
                    selectedIcon: Icon(Icons.queue),
                    label: Text('Queue'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.event_seat_outlined),
                    selectedIcon: Icon(Icons.event_seat),
                    label: Text('Chairs'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Bookings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.payments_outlined),
                    selectedIcon: Icon(Icons.payments),
                    label: Text('Earnings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.design_services_outlined),
                    selectedIcon: Icon(Icons.design_services),
                    label: Text('Services'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoadingSkeleton(height: 120),
              SizedBox(height: 16),
              LoadingSkeleton(height: 180),
            ],
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorView(
            message: error.toString(),
            onRetry: () => controller.refresh(),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    BarberDashboardState state,
    BarberDashboardController controller,
  ) {
    switch (selectedIndex) {
      case 1:
        return _queueView(context, state, controller);
      case 2:
        return _chairsView(context, state, controller);
      case 3:
        return _bookingsView(context, state, controller);
      case 4:
        return _earningsView(context, state);
      case 5:
        return _servicesView(context, state);
      default:
        return _overviewView(context, state, controller);
    }
  }

  Widget _overviewView(
    BuildContext context,
    BarberDashboardState state,
    BarberDashboardController controller,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      children: [
        Text('Today at a glance', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: width >= 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(label: 'Today', value: 'Rs. ${state.earnings.today.toStringAsFixed(0)}', icon: Icons.payments),
            MetricTile(label: 'Queue', value: '${state.queue.length}', icon: Icons.queue),
            MetricTile(label: 'Walk-ins', value: '${state.walkInCount}', icon: Icons.directions_walk),
            MetricTile(label: 'Status', value: state.isAvailable ? 'Available' : 'Offline', icon: Icons.toggle_on),
          ],
        ),
        const SizedBox(height: 16),
        DashboardSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live queue', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => setState(() => selectedIndex = 1),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.queue.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No customers in queue right now'),
                )
              else
                ...state.queue.take(2).map(
                      (customer) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QueueCard(
                          customer: customer,
                          onReady: () => controller.markReady(customer.id),
                          onStart: () => controller.markStarted(customer.id),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _queueView(
    BuildContext context,
    BarberDashboardState state,
    BarberDashboardController controller,
  ) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live queue', style: Theme.of(context).textTheme.headlineSmall),
            FilledButton.icon(
              onPressed: controller.acceptWalkIn,
              icon: const Icon(Icons.directions_walk),
              label: const Text('Accept walk-in'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.queue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Queue is clear. Customers will appear here in real time.'),
          )
        else
          ...state.queue.map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QueueCard(
                customer: customer,
                onReady: () => controller.markReady(customer.id),
                onStart: () => controller.markStarted(customer.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chairsView(
    BuildContext context,
    BarberDashboardState state,
    BarberDashboardController controller,
  ) {
    return ListView(
      children: [
        Text('Chair management', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...state.chairs.map(
          (chair) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardSectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chair.label, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          chair.currentCustomer == null
                              ? chair.status
                              : '${chair.status} - ${chair.currentCustomer}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: chair.status,
                    items: const [
                      DropdownMenuItem(value: 'AVAILABLE', child: Text('Available')),
                      DropdownMenuItem(value: 'RESERVED', child: Text('Reserved')),
                      DropdownMenuItem(value: 'OCCUPIED', child: Text('Occupied')),
                      DropdownMenuItem(value: 'CLEANING', child: Text('Cleaning')),
                      DropdownMenuItem(value: 'BLOCKED', child: Text('Blocked')),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setChairStatus(chair.id, value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookingsView(
    BuildContext context,
    BarberDashboardState state,
    BarberDashboardController controller,
  ) {
    return ListView(
      children: [
        Text('Booking management', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (state.queue.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No active bookings waiting for action.'),
          )
        else
          ...state.queue.map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DashboardSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${customer.serviceName} - ${customer.status}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => controller.markReady(customer.id),
                          child: const Text('Ready'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => controller.markStarted(customer.id),
                          child: const Text('Start'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _earningsView(BuildContext context, BarberDashboardState state) {
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      children: [
        Text('Earnings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: width >= 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(label: 'Today', value: 'Rs. ${state.earnings.today.toStringAsFixed(0)}', icon: Icons.today),
            MetricTile(label: 'Week', value: 'Rs. ${state.earnings.week.toStringAsFixed(0)}', icon: Icons.date_range),
            MetricTile(label: 'Month', value: 'Rs. ${state.earnings.month.toStringAsFixed(0)}', icon: Icons.calendar_month),
            MetricTile(label: 'Bookings', value: '${state.earnings.completedBookings}', icon: Icons.check_circle),
          ],
        ),
      ],
    );
  }

  Widget _servicesView(BuildContext context, BarberDashboardState state) {
    return ListView(
      children: [
        Text('Service management', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...state.activeServices.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardSectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.design_services_outlined),
                title: Text(service),
                subtitle: const Text('Enabled for booking and walk-in flow'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
