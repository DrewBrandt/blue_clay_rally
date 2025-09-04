import 'dart:async';

import 'package:blue_clay_rally/models/checkpoint.dart';
import 'package:blue_clay_rally/providers/app_state_provider.dart';
import 'package:blue_clay_rally/views/common/date_time_editor.dart';
import 'package:blue_clay_rally/views/common/icon_button.dart';
import 'package:blue_clay_rally/views/common/section_subtitle.dart';
import 'package:blue_clay_rally/views/common/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckpointEditor extends ConsumerWidget {
  const CheckpointEditor({super.key, required this.idx});

  final int idx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cp = ref.watch(checkpointSingleProvider(idx));
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black.withAlpha(150)),
      width: 500,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Align(alignment: Alignment.center, child: SectionTitle('Edit Checkpoint')),
                Align(
                  alignment: Alignment.centerRight,
                  child: LightIconButton(
                    tooltip: 'Close',
                    iconData: Icons.close_rounded,
                    onPressed: () {
                      ref.read(checkpointEditWindowProvider.notifier).state = null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: SectionSubTitle('Date/Time')),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: DateTimeEditor(
                value: cp?.time ?? DateTime.now(),
                useYear: false,
                onChanged: (d) {
                  if (cp == null || d == null || d.isAtSameMomentAs(cp.time)) return;
                  ref.read(appNotifierProvider.notifier).updateCheckpoint(cp, cp.copyWith(time: d));
                },
              ),
            ),
            SizedBox(height: 20),
            Divider(color: theme.dividerColor, thickness: 1),
            SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: SectionSubTitle('GPS Point')),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [Text('${cp?.tp.gps.latitude}'), Spacer(), Text('${cp?.tp.gps.longitude}')]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: CheckpointIdxControl(
                cpIdx: idx,
                min: 0,
                max: ref.read(currentTrackProvider)?.points.length ?? 1 - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckpointIdxControl extends ConsumerStatefulWidget {
  const CheckpointIdxControl({super.key, required this.cpIdx, required this.min, required this.max});

  final int cpIdx;
  final int min;
  final int max;

  @override
  ConsumerState<CheckpointIdxControl> createState() => _CheckpointIdxControlState();
}

class _CheckpointIdxControlState extends ConsumerState<CheckpointIdxControl> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _squelch = false;
  bool _invalid = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final cp = ref.read(checkpointSingleProvider(widget.cpIdx));
    _ctrl.text = (cp?.idx ?? widget.min).toString();

    _ctrl.addListener(_onTextChanged);
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit(); // commit on blur
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // === Same styling as DateTimeEditor ===
  InputDecoration _dec(String hint) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    hintText: hint,
    errorText: _invalid ? '' : null, // empty string to trigger red border
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    // Keep textbox in sync with external updates (but don't stomp while typing)
    ref.listen<Checkpoint?>(checkpointSingleProvider(widget.cpIdx), (prev, next) {
      final v = (next?.idx ?? widget.min).toString();
      if (!_focus.hasFocus && _ctrl.text != v) {
        _squelch = true;
        _ctrl.text = v;
        _squelch = false;
      }
    });

    final cp = ref.watch(checkpointSingleProvider(widget.cpIdx));
    final value = (cp?.idx ?? widget.min).toDouble();

    return Row(
      children: [
        SizedBox(
          width: 72, // similar width to DateTimeEditor fields
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            decoration: _dec('Index'),
            onSubmitted: (_) => _commit(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            divisions: (widget.max - widget.min).clamp(1, 100000),
            value: value.clamp(widget.min.toDouble(), widget.max.toDouble()),
            onChanged: (v) {
              final newIdx = v.round().clamp(widget.min, widget.max);
              final c = cp;
              if (c == null || newIdx == c.idx) return;

              ref.read(appNotifierProvider.notifier).updateCheckpoint(c, c.copyWith(idx: newIdx, tp: ref.read(currentTrackProvider)!.points[newIdx]));

              if (!_focus.hasFocus) {
                _squelch = true;
                _ctrl.text = newIdx.toString();
                _squelch = false;
              }
              // Slider changes are always valid
              if (_invalid) setState(() => _invalid = false);
            },
          ),
        ),
      ],
    );
  }

  void _onTextChanged() {
    if (_squelch) return;

    // Live validity for red border (don’t mutate app state yet)
    _invalid = !_isValidOrEmpty(_ctrl.text);
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _commit);
  }

  bool _isValidOrEmpty(String s) {
    if (s.isEmpty) return true;
    final n = int.tryParse(s);
    if (n == null) return false;
    return n >= widget.min && n <= widget.max;
  }

  void _commit() {
    final txt = _ctrl.text;
    if (txt.isEmpty) return;
    final n = int.tryParse(txt);
    _invalid = n == null || n < widget.min || n > widget.max;
    setState(() {}); // refresh border

    if (_invalid) return;

    final clamped = n!.clamp(widget.min, widget.max);
    final cp = ref.read(checkpointSingleProvider(widget.cpIdx));
    if (cp == null || clamped == cp.idx) return;

    ref.read(appNotifierProvider.notifier).updateCheckpoint(cp, cp.copyWith(idx: clamped));

    // Normalize textbox if clamped
    if (_ctrl.text != clamped.toString()) {
      _squelch = true;
      _ctrl.text = clamped.toString();
      _squelch = false;
    }
  }
}
