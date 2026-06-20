import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/bb_theme.dart';
import '../core/providers/theme_provider.dart';
import 'router/app_router.dart';

class BookBerApp extends ConsumerWidget {
  const BookBerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'BookBer',
      debugShowCheckedModeBanner: false,
      theme: BBTheme.light(),
      darkTheme: BBTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
