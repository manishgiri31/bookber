import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/design/bb_colors.dart';
import '../../../core/design/bb_tokens.dart';
import '../../../core/design/bb_typography.dart';
import '../dashboard/barber_provider.dart';

/// Full-screen QR code for this barber's permanent check-in token.
/// Intended to be displayed at the barber's workstation so customers
/// can scan it to check in when called.
class BarberQrScreen extends ConsumerWidget {
  const BarberQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bbColors;
    final state = ref.watch(barberDashProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('My Check-in QR'),
        backgroundColor: colors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpacing.pageHorizontal,
            vertical: BBSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BBSpacing.xl),
              // Instruction card
              Container(
                padding: const EdgeInsets.all(BBSpacing.base),
                decoration: BoxDecoration(
                  color: context.bbColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(BBRadius.lg),
                  border: Border.all(
                    color: context.bbColors.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Display this QR code at your workstation. When a customer '
                  'is called, they scan it to instantly check in and start '
                  'their service.',
                  style: BBTypography.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: BBSpacing.xxl),

              // QR area
              Expanded(
                child: Center(
                  child: state.isLoading
                      ? CircularProgressIndicator(color: context.bbColors.accent)
                      : state.profile?.checkInToken == null
                          ? _NoTokenWidget(
                              onRetry: () => ref
                                  .read(barberDashProvider.notifier)
                                  .refresh(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // QR code
                                Container(
                                  padding: const EdgeInsets.all(BBSpacing.xl),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(BBRadius.xl),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: state.profile!.checkInToken!,
                                    version: QrVersions.auto,
                                    size: 220,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: BBSpacing.xl),

                                // Barber name
                                Text(
                                  state.profile!.name,
                                  style: BBTypography.textTheme.headlineSmall
                                      ?.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: BBSpacing.xs),
                                Text(
                                  state.profile!.shopName,
                                  style: BBTypography.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: BBSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceVariant,
                                    borderRadius:
                                        BorderRadius.circular(BBRadius.full),
                                  ),
                                  child: Text(
                                    'Permanent QR — never changes',
                                    style:
                                        BBTypography.textTheme.labelSmall
                                            ?.copyWith(
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: BBSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTokenWidget extends StatelessWidget {
  const _NoTokenWidget({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_2, size: 64, color: colors.textTertiary),
        const SizedBox(height: BBSpacing.base),
        Text(
          'QR code not available yet',
          style: BBTypography.textTheme.titleMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BBSpacing.xs),
        Text(
          'Pull to refresh or tap below to try again.',
          style: BBTypography.textTheme.bodySmall
              ?.copyWith(color: colors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BBSpacing.xl),
        TextButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
