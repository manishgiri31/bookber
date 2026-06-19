import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

class MultiSelectChip extends StatefulWidget {
  const MultiSelectChip({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
  });

  final List<String> options;
  final Set<String> selectedOptions;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  State<MultiSelectChip> createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  void _toggle(String option) {
    final next = Set<String>.from(widget.selectedOptions);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      next.add(option);
    }
    widget.onSelectionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bbColors;

    return Wrap(
      spacing: BBSpacing.px8,
      runSpacing: BBSpacing.px8,
      children: widget.options.map((option) {
        final isSelected = widget.selectedOptions.contains(option);
        return GestureDetector(
          onTap: () => _toggle(option),
          child: AnimatedContainer(
            duration: BBMotion.fast,
            padding: const EdgeInsets.symmetric(
                horizontal: BBSpacing.px16, vertical: BBSpacing.px10),
            decoration: BoxDecoration(
              color: isSelected ? BBColors.brandPrimaryDim : colors.bgSurface,
              borderRadius: BBRadius.pill,
              border: Border.all(
                color: isSelected ? BBColors.brandPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              option,
              style: BBTypography.labelM.copyWith(
                color: isSelected ? BBColors.brandPrimary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
