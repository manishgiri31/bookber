import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/models/bookber_models.dart';
import '../providers/shop_providers.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopId));
    final servicesAsync = ref.watch(shopServicesProvider(widget.shopId));
    final barbersAsync = ref.watch(shopBarbersProvider(widget.shopId));
    final queueAsync = ref.watch(liveQueueProvider(widget.shopId));

    return shopAsync.when(
      data: (shop) {
        if (shop == null) {
          return Scaffold(
            backgroundColor: BookBerPalette.bgPrimary,
            appBar: AppBar(
              title: const Text('Shop Not Found'),
            ),
            body: const Center(
              child: Text('This shop could not be found'),
            ),
          );
        }
        return Scaffold(
          backgroundColor: BookBerPalette.bgPrimary,
          body: _buildShopDetail(context, shop, servicesAsync, barbersAsync, queueAsync),
        );
      },
      loading: () => Scaffold(
        backgroundColor: BookBerPalette.bgPrimary,
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: BookBerPalette.bgPrimary,
        appBar: AppBar(),
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildShopDetail(
    BuildContext context,
    Shop shop,
    AsyncValue<List<ServiceItem>> servicesAsync,
    AsyncValue<List<Barber>> barbersAsync,
    AsyncValue<dynamic> queueAsync,
  ) {
    return CustomScrollView(
      slivers: [
        // Hero Header
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: BookBerPalette.bgPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BookBerPalette.bgElevated,
                        BookBerPalette.bgPrimary,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: shop.imageUrl != null
                      ? Image.network(
                          shop.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container();
                          },
                        )
                      : null,
                ),
                // Back button
                Positioned(
                  top: 60,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: BookBerPalette.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Share button
                Positioned(
                  top: 60,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implement share
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: BookBerPalette.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Live badge
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: BookBerPalette.queueSafe,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Info
                const SizedBox(height: 24),
                Text(
                  shop.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: BookBerPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: BookBerPalette.primaryAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BookBerPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${shop.reviewCount})',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: BookBerPalette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // TODO: Open directions
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BookBerPalette.bgSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Directions',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BookBerPalette.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 16,
                      color: BookBerPalette.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${shop.distanceLabel} • ~${(shop.distanceKm * 2).toInt()} min drive',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: BookBerPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Live Queue Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(
                        color: BookBerPalette.primaryAccent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Wait',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: BookBerPalette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shop.waitTimeMinutes} mins',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: BookBerPalette.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: BookBerPalette.queueSafe.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 16,
                                  color: BookBerPalette.queueSafe,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.availableChairs} ahead',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: BookBerPalette.queueSafe,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.go('/queue/${widget.shopId}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BookBerPalette.primaryAccent,
                                side: BorderSide(
                                  color: BookBerPalette.primaryAccent,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Join Queue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go('/book/${widget.shopId}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BookBerPalette.primaryAccent,
                                foregroundColor: BookBerPalette.bgPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Book Slot',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Services section
                _buildServicesSection(servicesAsync),
                const SizedBox(height: 32),

                // Available chairs
                _buildAvailableChairsSection(shop),
                const SizedBox(height: 32),

                // Barbers section
                _buildBarbersSection(barbersAsync),
                const SizedBox(height: 32),

                // Reviews section (placeholder)
                _buildReviewsPlaceholder(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(AsyncValue<List<ServiceItem>> servicesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        servicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return const Center(
                child: Text('No services available'),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BookBerPalette.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x0FFFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BookBerPalette.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs. ${service.price}',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: BookBerPalette.primaryAccent,
                            ),
                          ),
                          Text(
                            '${service.durationMinutes} mins',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: BookBerPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => const Center(
            child: Text('Error loading services'),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableChairsSection(Shop shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Chairs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final isAvailable = index < shop.availableChairs;
            return Container(
              decoration: BoxDecoration(
                color: isAvailable
                    ? BookBerPalette.queueSafe
                    : BookBerPalette.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAvailable
                      ? BookBerPalette.queueSafe
                      : const Color(0x0FFFFFFF),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.event_seat,
                  color: isAvailable
                      ? BookBerPalette.bgPrimary
                      : BookBerPalette.textSecondary,
                  size: 24,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBarbersSection(AsyncValue<List<Barber>> barbersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barbers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        barbersAsync.when(
          data: (barbers) {
            if (barbers.isEmpty) {
              return const Center(
                child: Text('No barbers available'),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: barbers.length,
                itemBuilder: (context, index) {
                  final barber = barbers[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < barbers.length - 1 ? 12 : 0,
                    ),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: BookBerPalette.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0x0FFFFFFF),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: BookBerPalette.bgElevated,
                            child: Icon(
                              Icons.person,
                              color: BookBerPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              barber.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BookBerPalette.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: BookBerPalette.primaryAccent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                barber.rating.toStringAsFixed(1),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => const Center(
            child: Text('Error loading barbers'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Reviews feature coming soon',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: BookBerPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
