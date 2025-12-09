import 'package:flutter/material.dart';


// ---------------- QuickOption Class ----------------
class QuickOption {
  final String label;
  final double min;
  final double max;

  const QuickOption(this.label, this.min, this.max);
}

// ---------------- RangeSection Widget ----------------
class RangeSection extends StatefulWidget {
  final String title;
  final double currentMin;
  final double currentMax;
  final double absoluteMin;
  final double absoluteMax;
  final double step;
  final String Function(double) formatFunction;
  final Function(double, double) onChanged;
  final List<QuickOption> quickOptions;

  const RangeSection({
    Key? key,
    required this.title,
    required this.currentMin,
    required this.currentMax,
    required this.absoluteMin,
    required this.absoluteMax,
    required this.step,
    required this.formatFunction,
    required this.onChanged,
    required this.quickOptions,
  }) : super(key: key);

  @override
  State<RangeSection> createState() => _RangeSectionState();
}

class _RangeSectionState extends State<RangeSection> {
  @override
  Widget build(BuildContext context) {
    final divisions = ((widget.absoluteMax - widget.absoluteMin) / widget.step)
        .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(widget.currentMin, widget.currentMax),
          min: widget.absoluteMin,
          max: widget.absoluteMax,
          divisions: divisions,
          labels: RangeLabels(
            widget.formatFunction(widget.currentMin),
            widget.formatFunction(widget.currentMax),
          ),
          activeColor: Colors.blue,
          onChanged: (values) {
            widget.onChanged(values.start, values.end);
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.quickOptions.map((option) {
            final isSelected =
                widget.currentMin == option.min &&
                widget.currentMax == option.max;
            return GestureDetector(
              onTap: () => widget.onChanged(option.min, option.max),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
