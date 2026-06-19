import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/models/bookber_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/snackbar.dart';
import '../payment/providers/payment_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();

  static const _positiveTags = <String>[
    'Great haircut',
    'Clean shop',
    'Friendly barber',
    'On time',
    'Good value',
  ];

  static const _negativeTags = <String>[
    'Long wait',
    'Could be cleaner',
    'Service issue',
    'Pricing issue',
    'Not satisfied',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reviewFormProvider.notifier).state = ReviewFormState(bookingId: widget.bookingId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final form = ref.watch(reviewFormProvider);
    final bookingAsync = ref.watch(bookingDetailsProvider(widget.bookingId));
    final isSubmitting = ref.watch(reviewSubmittingProvider);
    final isUploading = ref.watch(reviewPhotoUploadingProvider);
    final tags = form.rating >= 4 ? _positiveTags : _negativeTags;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: () => context.go(RoutePaths.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: BBSpacing.px20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bookingAsync.when(
              loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _BookingSummaryFallback(bookingId: widget.bookingId),
              data: (booking) => _BookingSummary(booking: booking),
            ),
            const SizedBox(height: BBSpacing.px32),
            Text(
              'How was your experience?',
              style: BBTypography.headingS.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: BBSpacing.px16),
            _Stars(
              rating: form.rating,
              onChanged: (rating) {
                ref.read(reviewFormProvider.notifier).state = form.copyWith(
                      rating: rating,
                      selectedTags: const <String>[],
                    );
              },
            ),
            const SizedBox(height: BBSpacing.px32),
            _QuickTags(
              tags: tags,
              selectedTags: form.selectedTags,
              onToggle: (tag) => _toggleTag(form, tag),
            ),
            const SizedBox(height: BBSpacing.px32),
            Text(
              'Tell us more (optional)',
              style: BBTypography.labelL.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: BBSpacing.px12),
            Container(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BBRadius.md,
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 280,
                style: BBTypography.bodyM.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What did you love? What could be better?',
                  hintStyle: BBTypography.bodyM.copyWith(color: colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(BBSpacing.px16),
                  counterText: '',
                ),
                onChanged: (comment) {
                  ref.read(reviewFormProvider.notifier).state = form.copyWith(comment: comment);
                },
              ),
            ),
            const SizedBox(height: BBSpacing.px8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${form.comment.length}/280',
                style: BBTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: BBSpacing.px32),
            _PhotoPicker(
              photoUrls: form.photoUrls,
              isUploading: isUploading,
              onAdd: _pickAndUploadPhoto,
              onRemove: (url) {
                ref.read(reviewFormProvider.notifier).state = form.copyWith(
                      photoUrls: form.photoUrls.where((item) => item != url).toList(),
                    );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        canSubmit: form.rating > 0 && !isSubmitting && !isUploading,
        isSubmitting: isSubmitting,
        onSubmit: () => _submitReview(context),
      ),
    );
  }

  void _toggleTag(ReviewFormState form, String tag) {
    final tags = [...form.selectedTags];
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    ref.read(reviewFormProvider.notifier).state = form.copyWith(selectedTags: tags);
  }

  Future<void> _pickAndUploadPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    ref.read(reviewPhotoUploadingProvider.notifier).state = true;
    final result = await ref.read(reviewRepositoryProvider).uploadPhotos([File(image.path)]);
    ref.read(reviewPhotoUploadingProvider.notifier).state = false;
    if (!mounted) return;

    switch (result) {
      case ApiSuccess<List<String>>(:final data):
        final form = ref.read(reviewFormProvider);
        ref.read(reviewFormProvider.notifier).state = form.copyWith(
              photoUrls: [...form.photoUrls, ...data].take(3).toList(),
            );
      case ApiError<List<String>>(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $message')),
        );
    }
  }

  Future<void> _submitReview(BuildContext context) async {
    ref.read(reviewSubmittingProvider.notifier).state = true;
    final form = ref.read(reviewFormProvider).copyWith(bookingId: widget.bookingId);
    final result = await ref.read(reviewRepositoryProvider).submitReview(form);
    ref.read(reviewSubmittingProvider.notifier).state = false;
    if (!mounted) return;

    switch (result) {
      case ApiSuccess<void>():
        BookerSnackbar.success(context, 'Thanks for your feedback!');
        context.go(RoutePaths.home);
      case ApiError<void>(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review failed: $message')),
        );
    }
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(Icons.content_cut, color: colors.textSecondary),
        ),
        const SizedBox(width: BBSpacing.px16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.barberName,
                style: BBTypography.headingS.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: BBSpacing.px4),
              Text(
                booking.shopName,
                style: BBTypography.bodyM.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingSummaryFallback extends StatelessWidget {
  const _BookingSummaryFallback({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Booking $bookingId',
      style: BBTypography.headingS.copyWith(color: context.bbColors.textPrimary),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({
    required this.rating,
    required this.onChanged,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= rating;
        return IconButton(
          onPressed: () => onChanged(value),
          icon: Icon(
            Icons.star,
            color: selected ? BBColors.brandSecondary : context.bbColors.textDisabled,
            size: 32,
          ),
        );
      }),
    );
  }
}

class _QuickTags extends StatelessWidget {
  const _QuickTags({
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  final List<String> tags;
  final List<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Wrap(
      spacing: BBSpacing.px8,
      runSpacing: BBSpacing.px8,
      children: tags.map((tag) {
        final selected = selectedTags.contains(tag);
        return FilterChip(
          selected: selected,
          label: Text(tag),
          onSelected: (_) => onToggle(tag),
          backgroundColor: colors.bgSurface,
          selectedColor: BBColors.brandPrimaryDim,
          checkmarkColor: BBColors.brandPrimary,
          labelStyle: BBTypography.labelM.copyWith(
            color: selected ? BBColors.brandPrimary : colors.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoUrls,
    required this.isUploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photoUrls;
  final bool isUploading;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add photos (optional)',
          style: BBTypography.labelL.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: BBSpacing.px12),
        Row(
          children: [
            if (photoUrls.length < 3)
              GestureDetector(
                onTap: isUploading ? null : onAdd,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BBRadius.md,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.add, size: 32, color: colors.textSecondary),
                ),
              ),
            ...photoUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.only(left: BBSpacing.px12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BBRadius.md,
                      child: Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(url),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: BBColors.error,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Container(
      padding: const EdgeInsets.all(BBSpacing.px20),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: BBTouchTarget.button,
          child: ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: BBColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.bgElevated,
              disabledForegroundColor: colors.textDisabled,
              shape: RoundedRectangleBorder(borderRadius: BBRadius.pill),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Submit Review', style: BBTypography.button),
          ),
        ),
      ),
    );
  }
}
