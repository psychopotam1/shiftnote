import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

Future<TimeOfDay?> showGlassTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Select time',
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return _GlassTimePickerSheet(
        initialTime: initialTime,
        title: title,
      );
    },
  );
}

class _GlassTimePickerSheet extends StatefulWidget {
  const _GlassTimePickerSheet({
    required this.initialTime,
    required this.title,
  });

  final TimeOfDay initialTime;
  final String title;

  @override
  State<_GlassTimePickerSheet> createState() => _GlassTimePickerSheetState();
}

class _GlassTimePickerSheetState extends State<_GlassTimePickerSheet> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottomInset),
      child: GlassContainer(
        blur: 20,
        borderRadius: BorderRadius.circular(34),
        color: const Color(0xFF151B25).withOpacity(0.88),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8EA3FF).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF8EA3FF).withOpacity(0.22),
                        ),
                      ),
                      child: Text(
                        '${_twoDigits(_selectedHour)}:${_twoDigits(_selectedMinute)}',
                        style: const TextStyle(
                          color: Color(0xFFB9C5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.08),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _PickerColumn(
                          controller: _hourController,
                          itemCount: 24,
                          selectedValue: _selectedHour,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedHour = index;
                            });
                          },
                          itemBuilder: (index, isSelected) {
                            return _PickerItem(
                              label: _twoDigits(index),
                              isSelected: isSelected,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.86),
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PickerColumn(
                          controller: _minuteController,
                          itemCount: 60,
                          selectedValue: _selectedMinute,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedMinute = index;
                            });
                          },
                          itemBuilder: (index, isSelected) {
                            return _PickerItem(
                              label: _twoDigits(index),
                              isSelected: isSelected,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _BottomButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BottomButton(
                        label: 'Done',
                        isPrimary: true,
                        onTap: () {
                          Navigator.pop(
                            context,
                            TimeOfDay(
                              hour: _selectedHour,
                              minute: _selectedMinute,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedValue,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedValue;
  final ValueChanged<int> onSelectedItemChanged;
  final Widget Function(int index, bool isSelected) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
        ),
        CupertinoPicker.builder(
          scrollController: controller,
          itemExtent: 54,
          diameterRatio: 1.45,
          squeeze: 1.1,
          useMagnifier: false,
          selectionOverlay: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onSelectedItemChanged: onSelectedItemChanged,
          childCount: itemCount,
          itemBuilder: (context, index) {
            return itemBuilder(index, index == selectedValue);
          },
        ),
      ],
    );
  }
}

class _PickerItem extends StatelessWidget {
  const _PickerItem({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 140),
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.26),
          fontSize: isSelected ? 38 : 26,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          height: 1,
        ),
        child: Text(label),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 16,
      borderRadius: BorderRadius.circular(22),
      color: isPrimary
          ? const Color(0xFF8EA3FF).withOpacity(0.22)
          : Colors.white.withOpacity(0.06),
      border: Border.all(
        color: isPrimary
            ? const Color(0xFFB9C5FF).withOpacity(0.24)
            : Colors.white.withOpacity(0.10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : Colors.white.withOpacity(0.86),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}