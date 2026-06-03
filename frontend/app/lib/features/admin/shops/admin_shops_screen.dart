import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

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
      backgroundColor: BookBerPalette.bgPrimary,
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
                  color: BookBerPalette.textPrimary,
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
                        color: BookBerPalette.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: BookBerPalette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search shops...',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: BookBerPalette.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: BookBerPalette.textSecondary,
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
                      color: BookBerPalette.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(
                          Icons.filter_list,
                          color: BookBerPalette.textSecondary,
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: BookBerPalette.textPrimary,
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BookBerPalette.primaryAccent),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Error loading shops',
                    style: TextStyle(color: BookBerPalette.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
        onTap: (index) {
          // TODO: Navigate to respective screens
        },
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
        statusColor = BookBerPalette.queueSafe;
        statusLabel = 'Active';
        break;
      case ShopStatus.inactive:
        statusColor = BookBerPalette.textMuted;
        statusLabel = 'Inactive';
        break;
      case ShopStatus.pending:
        statusColor = BookBerPalette.warningAmber;
        statusLabel = 'Pending';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
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
                        color: BookBerPalette.textPrimary,
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
                        style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: BookBerPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: BookBerPalette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.todayBookings} today',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: BookBerPalette.warningAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: BookBerPalette.textPrimary,
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
            activeColor: BookBerPalette.queueSafe,
          ),
        ],
      ),
    );
  }
}
