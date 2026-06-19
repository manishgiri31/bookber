import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: BBSpacing.px24,
            right: BBSpacing.px24,
            top: BBSpacing.px24,
            bottom: MediaQuery.of(context).viewInsets.bottom + BBSpacing.px24,
          ),
          child: Column(
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: BBColors.brandPrimary,
                        borderRadius: BBRadius.md,
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: BBTypography.displayS.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: BBSpacing.px12),
                    Text(
                      'BookBer',
                      style: BBTypography.headingL.copyWith(
                          color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BBSpacing.px32),

              // Card
              Container(
                padding: BBSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BBRadius.card,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: BBTypography.displayS
                            .copyWith(color: colors.textPrimary),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: BBSpacing.px8),
                        Text(
                          subtitle!,
                          style: BBTypography.bodyM
                              .copyWith(color: colors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: BBSpacing.px24),
                    ],
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
