import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/design_system.dart';

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
  void _toggleSelection(String option) {
    final newSelection = Set<String>.from(widget.selectedOptions);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else {
      newSelection.add(option);
    }
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.options.map((option) {
        final isSelected = widget.selectedOptions.contains(option);
        return GestureDetector(
          onTap: () => _toggleSelection(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? BookBerPalette.primaryAccent.withValues(alpha: 0.12)
                  : BookBerPalette.bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? BookBerPalette.primaryAccent
                    : const Color(0x0FFFFFFF),
                width: 1,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? BookBerPalette.primaryAccent
                    : BookBerPalette.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
