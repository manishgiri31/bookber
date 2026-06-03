import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookerBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;

  const BookerBottomSheet({Key? key, required this.child, this.title}) : super(key: key);

  static Future<T?> show<T>(BuildContext context, {required Widget child, String? title, bool isScrollControlled = true}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookerBottomSheet(child: child, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(4))),
              if (title != null) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(title!, style: Theme.of(context).textTheme.bodyLarge),
                ]),
              ],
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(controller: scrollController, child: child)),
            ],
          ),
        );
      },
    );
  }
}
