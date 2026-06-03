import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../providers/shop_providers.dart';
import '../widgets/customer_nav_bar.dart';
import '../widgets/shop_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        if (_currentPromoPage < 1) {
          _promoController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _promoController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        _startAutoScroll();
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_getGreeting(), Aasmaan 👋',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ready for a fresh cut?',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: BookBerPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BookBerPalette.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 24,
                                color: BookBerPalette.textPrimary,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: BookBerPalette.primaryAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Location pill
                    GestureDetector(
                      onTap: () {
                        // TODO: Open location picker bottom sheet
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: BookBerPalette.bgSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: BookBerPalette.primaryAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ludhiana, Punjab',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: BookBerPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: BookBerPalette.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    GestureDetector(
                      onTap: () => context.go('/explore'),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: BookBerPalette.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.search,
                              size: 20,
                              color: BookBerPalette.primaryAccent,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Search barbers, shops, services...',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: BookBerPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Promo banner
                    SizedBox(
                      height: 160,
                      child: PageView(
                        controller: _promoController,
                        onPageChanged: (index) {
                          setState(() => _currentPromoPage = index);
                        },
                        children: [
                          _buildPromoCard(
                            'BookBer Members get 20% off',
                            gradient: const LinearGradient(
                              colors: [BookBerPalette.primaryAccent, Color(0xFF007A69)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          _buildPromoCard(
                            'New shops near you',
                            gradient: const LinearGradient(
                              colors: [BookBerPalette.bgElevated, BookBerPalette.bgPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            hasTealAccent: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Promo indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        2,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPromoPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPromoPage == index
                                ? BookBerPalette.primaryAccent
                                : BookBerPalette.bgElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nearby Shops section
                    _buildSectionHeader('Nearby Shops', 'See all'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: ref.watch(nearbyShopsProvider('Ludhiana')).when(
                        data: (shops) {
                          if (shops.isEmpty) {
                            return const Center(
                              child: Text('No shops available'),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: shops.length,
                            itemBuilder: (context, index) {
                              final shop = shops[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < shops.length - 1 ? 12 : 0,
                                ),
                                child: ShopCard(
                                  shopName: shop.name,
                                  rating: shop.rating,
                                  reviewCount: shop.reviewCount,
                                  distance: shop.distanceLabel,
                                  waitTime: shop.waitTimeLabel,
                                  availableChairs: shop.availableChairs,
                                  imageUrl: shop.imageUrl,
                                  onTap: () => context.go('/shop/${shop.id}'),
                                  onBookTap: () => context.go('/shop/${shop.id}'),
                                  isLoading: false,
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error: $error'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Book section (also from nearby shops, showing top quick options)
                    _buildSectionHeader('Quick Book', null),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: ref.watch(nearbyShopsProvider('Ludhiana')).when(
                        data: (shops) {
                          final quickShops = shops.take(3).toList();
                          if (quickShops.isEmpty) {
                            return const Center(
                              child: Text('No shops available'),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: quickShops.length,
                            itemBuilder: (context, index) {
                              final shop = quickShops[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < quickShops.length - 1 ? 12 : 0,
                                ),
                                child: ShopCard(
                                  shopName: shop.name,
                                  rating: shop.rating,
                                  reviewCount: shop.reviewCount,
                                  distance: shop.distanceLabel,
                                  waitTime: shop.waitTimeLabel,
                                  availableChairs: shop.availableChairs,
                                  imageUrl: shop.imageUrl,
                                  onTap: () => context.go('/shop/${shop.id}'),
                                  onBookTap: () => context.go('/shop/${shop.id}'),
                                  isLoading: false,
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => const Center(
                          child: Text('Error loading shops'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Popular Services section
                    _buildSectionHeader('Popular Services', null),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          final services = ['Haircut', 'Beard', 'Shave', 'Fade', 'Color', 'Kids'];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < 5 ? 12 : 0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: BookBerPalette.bgSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x0FFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                services[index],
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: BookBerPalette.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Bottom navigation
            CustomerNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                // TODO: Navigate to different screens
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BookBerPalette.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: () {
              // TODO: Navigate to see all
            },
            child: Text(
              action,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.primaryAccent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCard(String text, {Gradient? gradient, bool hasTealAccent = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BookBerPalette.textPrimary,
              ),
            ),
          ),
          if (hasTealAccent)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BookBerPalette.primaryAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Explore',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BookBerPalette.bgPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
