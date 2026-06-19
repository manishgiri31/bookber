import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../providers/admin_providers.dart';

class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(adminShopsProvider);

    return Scaffold(
      backgroundColor: context.bbColors.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Shop Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.bbColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search + filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.bbColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.bbColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search shops...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: context.bbColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.bbColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.bbColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        underline: const SizedBox.shrink(),
                        icon: Icon(
                          Icons.filter_list,
                          color: context.bbColors.textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.bbColors.textPrimary,
                        ),
                        items: ['All', 'Active', 'Inactive', 'Pending'].map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedFilter = value ?? 'All');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shop list
            Expanded(
              child: shopsAsync.when(
                data: (shops) => _ShopList(shops: shops),
                loading: () => Center(
                  child: CircularProgressIndicator(color: BBColors.brandPrimary),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Error loading shops',
                    style: TextStyle(color: context.bbColors.textSecondary),
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

class _ShopList extends StatelessWidget {
  const _ShopList({required this.shops});

  final List<AdminShop> shops;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return _ShopAdminTile(shop: shop);
      },
    );
  }
}

class _ShopAdminTile extends ConsumerWidget {
  const _ShopAdminTile({required this.shop});

  final AdminShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusLabel;

    switch (shop.status) {
      case ShopStatus.active:
        statusColor = BBColors.success;
        statusLabel = 'Active';
        break;
      case ShopStatus.inactive:
        statusColor = context.bbColors.textDisabled;
        statusLabel = 'Inactive';
        break;
      case ShopStatus.pending:
        statusColor = BBColors.warning;
        statusLabel = 'Pending';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bbColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Shop info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.bbColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  shop.city,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: context.bbColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.bbColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.todayBookings} today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.bbColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.star,
                      size: 14,
                      color: BBColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.bbColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status toggle
          Switch(
            value: shop.status == ShopStatus.active,
            onChanged: (value) async {
              await ref.read(adminActionsProvider.notifier).updateShopStatus(
                    shop.id,
                    value ? 'active' : 'inactive',
                  );
            },
            activeColor: BBColors.success,
          ),
        ],
      ),
    );
  }
}
