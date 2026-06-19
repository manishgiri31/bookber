import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/design/theme.dart';
import '../../../core/design/tokens.dart';
import '../../payment/providers/payment_providers.dart';

class PhotoUploadWidget extends ConsumerWidget {
  const PhotoUploadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final formState = ref.watch(reviewFormProvider);
    final photos = formState.photos;

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
            if (photos.length < 3)
              GestureDetector(
                onTap: () => _pickImage(ref),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BBRadius.md,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Icon(Icons.add, size: 32, color: colors.textSecondary),
                ),
              ),
            ...photos.map((photo) {
              return Padding(
                padding: const EdgeInsets.only(left: BBSpacing.px12),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.bgElevated,
                        borderRadius: BBRadius.md,
                      ),
                      child: ClipRRect(
                        borderRadius: BBRadius.md,
                        child: Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: colors.bgElevated);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(reviewFormProvider.notifier).removePhoto(photo),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: BBColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BBSpacing.px8),
            child: Text(
              '${photos.length}/3 photos',
              style: BBTypography.caption.copyWith(color: colors.textSecondary),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(reviewFormProvider.notifier).addPhoto(image.path);
    }
  }
}
