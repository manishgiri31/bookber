import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/design_system.dart';
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
    final form = ref.watch(reviewFormProvider);
    final bookingAsync = ref.watch(bookingDetailsProvider(widget.bookingId));
    final isSubmitting = ref.watch(reviewSubmittingProvider);
    final isUploading = ref.watch(reviewPhotoUploadingProvider);
    final tags = form.rating >= 4 ? _positiveTags : _negativeTags;

    return Scaffold(
      backgroundColor: BookBerPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: BookBerPalette.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: BookBerPalette.textPrimary),
          onPressed: () => context.go(RoutePaths.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
            const SizedBox(height: 32),
            Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BookBerPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _Stars(
              rating: form.rating,
              onChanged: (rating) {
                ref.read(reviewFormProvider.notifier).state = form.copyWith(
                      rating: rating,
                      selectedTags: const <String>[],
                    );
              },
            ),
            const SizedBox(height: 32),
            _QuickTags(
              tags: tags,
              selectedTags: form.selectedTags,
              onToggle: (tag) => _toggleTag(form, tag),
            ),
            const SizedBox(height: 32),
            Text(
              'Tell us more (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BookBerPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: BookBerPalette.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x0FFFFFFF)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 280,
                style: GoogleFonts.dmSans(fontSize: 14, color: BookBerPalette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What did you love? What could be better?',
                  hintStyle: GoogleFonts.dmSans(fontSize: 14, color: BookBerPalette.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                onChanged: (comment) {
                  ref.read(reviewFormProvider.notifier).state = form.copyWith(comment: comment);
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${form.comment.length}/280',
                style: GoogleFonts.dmSans(fontSize: 12, color: BookBerPalette.textSecondary),
              ),
            ),
            const SizedBox(height: 32),
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
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: BookBerPalette.bgElevated,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.content_cut, color: BookBerPalette.textSecondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.barberName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BookBerPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.shopName,
                style: GoogleFonts.dmSans(fontSize: 14, color: BookBerPalette.textSecondary),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BookBerPalette.textPrimary,
      ),
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
            color: selected ? const Color(0xFFF59E0B) : BookBerPalette.textMuted,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final selected = selectedTags.contains(tag);
        return FilterChip(
          selected: selected,
          label: Text(tag),
          onSelected: (_) => onToggle(tag),
          backgroundColor: BookBerPalette.bgSurface,
          selectedColor: BookBerPalette.primaryAccent.withValues(alpha: 0.16),
          checkmarkColor: BookBerPalette.primaryAccent,
          labelStyle: GoogleFonts.dmSans(
            color: selected ? BookBerPalette.primaryAccent : BookBerPalette.textSecondary,
            fontWeight: FontWeight.w600,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add photos (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BookBerPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (photoUrls.length < 3)
              GestureDetector(
                onTap: isUploading ? null : onAdd,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BookBerPalette.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x0FFFFFFF)),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 32, color: BookBerPalette.textSecondary),
                ),
              ),
            ...photoUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                          backgroundColor: BookBerPalette.urgentRed,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: BookBerPalette.bgSurface,
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: BookBerPalette.primaryAccent,
              foregroundColor: BookBerPalette.bgPrimary,
              disabledBackgroundColor: BookBerPalette.bgElevated,
              disabledForegroundColor: BookBerPalette.textMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BookBerPalette.bgPrimary,
                    ),
                  )
                : Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
