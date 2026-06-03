import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/design_system.dart';
import '../../../core/widgets/shimmer_loader.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({
    super.key,
    required this.shopName,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.waitTime,
    required this.availableChairs,
    this.imageUrl,
    this.onTap,
    this.onBookTap,
    this.isLoading = false,
  });

  final String shopName;
  final double rating;
  final int reviewCount;
  final String distance;
  final String waitTime;
  final int availableChairs;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmer();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          color: BookBerPalette.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x0FFFFFFF),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    color: BookBerPalette.bgElevated,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: BookBerPalette.bgElevated,
                              );
                            },
                          ),
                        )
                      : null,
                ),
                // BookBer Verified badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BookBerPalette.primaryAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Verified',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BookBerPalette.bgPrimary,
                      ),
                    ),
                  ),
                ),
                // Available chairs badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: availableChairs > 0
                          ? BookBerPalette.queueSafe
                          : BookBerPalette.queueCritical,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$availableChairs',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name
                  Text(
                    shopName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BookBerPalette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: BookBerPalette.primaryAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BookBerPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Wait time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: BookBerPalette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waitTime,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: BookBerPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Book Now button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onBookTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BookBerPalette.primaryAccent,
                        foregroundColor: BookBerPalette.bgPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      width: 220,
      height: 280,
      decoration: BoxDecoration(
        color: BookBerPalette.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x0FFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          ShimmerLoader(
            width: 220,
            height: 140,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name shimmer
                ShimmerLoader(
                  width: 150,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                // Rating shimmer
                ShimmerLoader(
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                // Distance shimmer
                ShimmerLoader(
                  width: 60,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                // Wait time shimmer
                ShimmerLoader(
                  width: 70,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                // Button shimmer
                ShimmerLoader(
                  width: double.infinity,
                  height: 40,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
