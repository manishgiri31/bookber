import 'package:flutter/material.dart';

import '../design/bb_colors.dart';
import '../design/bb_tokens.dart';
import '../design/bb_typography.dart';
import '../errors/exceptions.dart';
import 'bb_button.dart';

class BBErrorWidget extends StatelessWidget {
  const BBErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.fullScreen = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;
    final info = _parseError(error);

    Widget content = Padding(
      padding: const EdgeInsets.all(BBSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              info.icon,
              size: 28,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: BBSpacing.base),
          Text(
            info.title,
            style: BBTypography.textTheme.titleLarge?.copyWith(
              color: colors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BBSpacing.sm),
          Text(
            info.message,
            style: BBTypography.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: BBSpacing.xl),
            BBButton(
              label: 'Try Again',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              expand: false,
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: content),
      );
    }
    return Center(child: content);
  }

  _ErrorInfo _parseError(Object error) {
    return switch (error) {
      NoInternetException() => const _ErrorInfo(
          title: 'No Connection',
          message: 'Check your internet connection and try again.',
          icon: Icons.wifi_off_rounded,
        ),
      TimeoutException() => const _ErrorInfo(
          title: 'Request Timed Out',
          message: 'The server took too long to respond. Try again.',
          icon: Icons.timer_off_outlined,
        ),
      UnauthorizedException() => const _ErrorInfo(
          title: 'Session Expired',
          message: 'Please sign in again to continue.',
          icon: Icons.lock_outline_rounded,
        ),
      ServerException() => const _ErrorInfo(
          title: 'Server Error',
          message: 'Something went wrong on our end. We\'re working on it.',
          icon: Icons.cloud_off_rounded,
        ),
      AppException(:final message) => _ErrorInfo(
          title: 'Something Went Wrong',
          message: message,
          icon: Icons.error_outline_rounded,
        ),
      _ => _ErrorInfo(
          title: 'Something Went Wrong',
          message: error.toString(),
          icon: Icons.error_outline_rounded,
        ),
    };
  }
}

class _ErrorInfo {
  const _ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;
}
