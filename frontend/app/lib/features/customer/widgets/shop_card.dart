import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/components/bb_skeleton.dart';
import '../../../core/components/bb_status.dart';
import '../../../core/models/bookber_models.dart';

// ─────────────────────────────────────────────────────────────
// SHOP CARD — horizontal scroll card for nearby shops
// ─────────────────────────────────────────────────────────────

class ShopCard extends StatelessWidget {
  const ShopCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: BBColors.bgSurface,
          borderRadius: BBRadius.card,
          border: Border.all(color: BBColors.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ─────────────────────────────────────
            _ShopImage(imageUrl: shop.imageUrl, isOpen: shop.isOpen),

            // ── Info ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(BBSpacing.px12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: BBTypography.headingS,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: BBSpacing.px4),
                        Text(
                          shop.distanceLabel,
                          style: BBTypography.bodyS,
                          maxLines: 1,
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        BBRatingBadge(
                          rating: shop.rating,
                          reviewCount: shop.reviewCount,
                        ),
                        const Spacer(),
                        if (shop.waitMinutes != null)
                          BBWaitBadge(minutes: shop.waitMinutes!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHOP LIST CARD — full-width card for the open shops list
// ─────────────────────────────────────────────────────────────

class ShopListCard extends StatelessWidget {
  const ShopListCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BBColors.bgSurface,
          borderRadius: BBRadius.card,
          border: Border.all(color: BBColors.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BBRadius.r20),
                bottomLeft: Radius.circular(BBRadius.r20),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: shop.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: shop.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: BBColors.bgElevated,
                          child: const _ShopImagePlaceholder(),
                        ),
                        errorWidget: (_, __, ___) =>
                            Container(color: BBColors.bgElevated,
                              child: const _ShopImagePlaceholder()),
                      )
                    : Container(
                        color: BBColors.bgElevated,
                        child: const _ShopImagePlaceholder(),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(BBSpacing.px14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            style: BBTypography.headingM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: BBSpacing.px8),
                        BBStatusPill(
                          type: shop.isOpen
                              ? BBStatusType.open
                              : BBStatusType.closed,
                          label: shop.isOpen ? 'Open' : 'Closed',
                        ),
                      ],
                    ),
                    const SizedBox(height: BBSpacing.px4),
                    Text(
                      shop.address,
                      style: BBTypography.bodyS,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BBSpacing.px10),
                    Row(
                      children: [
                        BBRatingBadge(
                          rating: shop.rating,
                          reviewCount: shop.reviewCount,
                        ),
                        const SizedBox(width: BBSpacing.px10),
                        Icon(
                          Icons.location_on_outlined,
                          size: BBIconSize.xs,
                          color: BBColors.textDisabled,
                        ),
                        const SizedBox(width: BBSpacing.px4),
                        Text(shop.distanceLabel, style: BBTypography.labelS),
                        if (shop.waitMinutes != null) ...[
                          const Spacer(),
                          BBWaitBadge(minutes: shop.waitMinutes!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: BBSpacing.px12),
              child: Icon(
                Icons.chevron_right_rounded,
                size: BBIconSize.md,
                color: BBColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INTERNAL WIDGETS
// ─────────────────────────────────────────────────────────────

class _ShopImage extends StatelessWidget {
  const _ShopImage({required this.imageUrl, required this.isOpen});
  final String? imageUrl;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 120,
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: BBColors.bgElevated,
                    child: const _ShopImagePlaceholder()),
                  errorWidget: (_, __, ___) => Container(
                    color: BBColors.bgElevated,
                    child: const _ShopImagePlaceholder(),
                  ),
                )
              : Container(
                  color: BBColors.bgElevated,
                  child: const _ShopImagePlaceholder(),
                ),
        ),

        // Status overlay
        Positioned(
          top: BBSpacing.px8,
          left: BBSpacing.px8,
          child: BBStatusPill(
            type: isOpen ? BBStatusType.open : BBStatusType.closed,
            label: isOpen ? 'Open' : 'Closed',
          ),
        ),
      ],
    );
  }
}

class _ShopImagePlaceholder extends StatelessWidget {
  const _ShopImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.storefront_outlined,
        size: BBIconSize.xl,
        color: BBColors.textDisabled,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON VARIANT
// ─────────────────────────────────────────────────────────────

class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: BBColors.bgSurface,
        borderRadius: BBRadius.card,
        border: Border.all(color: BBColors.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BBSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(BBRadius.r20),
              topRight: Radius.circular(BBRadius.r20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(BBSpacing.px12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BBSkeleton(width: 120, height: 14),
                const SizedBox(height: BBSpacing.px6),
                BBSkeleton(width: 80, height: 12),
                const SizedBox(height: BBSpacing.px10),
                Row(
                  children: [
                    BBSkeleton(width: 48, height: 20),
                    const Spacer(),
                    BBSkeleton(width: 40, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
