import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/design_system.dart';
import '../../payment/providers/payment_providers.dart';

class PhotoUploadWidget extends ConsumerWidget {
  const PhotoUploadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(reviewFormProvider);
    final photos = formState.photos;

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
            // Add photo button
            if (photos.length < 3)
              GestureDetector(
                onTap: () => _pickImage(ref),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BookBerPalette.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x0FFFFFFF),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 32,
                    color: BookBerPalette.textSecondary,
                  ),
                ),
              ),
            // Photo thumbnails
            ...photos.map((photo) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: BookBerPalette.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: BookBerPalette.bgElevated,
                            );
                          },
                        ),
                      ),
                    ),
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => ref.read(reviewFormProvider.notifier).removePhoto(photo),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: BookBerPalette.urgentRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        if (photos.length > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${photos.length}/3 photos',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: BookBerPalette.textSecondary,
              ),
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
