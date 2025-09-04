import 'dart:async';

import 'package:blue_clay_rally/views/common/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateTimeEditor extends StatefulWidget {
  const DateTimeEditor({
    super.key,
    required this.value,
    this.includeSeconds = false,
    this.onChanged,
    this.label,
    this.allowRollover = false, // if false, invalid dates are highlighted
    this.use24h = true,
    this.useYear = true,
  });

  final DateTime? value;
  final bool includeSeconds;
  final bool allowRollover;
  final bool use24h;
  final bool useYear;
  final String? label;
  final ValueChanged<DateTime?>? onChanged;

  @override
  State<DateTimeEditor> createState() => _DateTimeEditorState();
}

class _DateTimeEditorState extends State<DateTimeEditor> {
  late final _year = TextEditingController();
  late final _month = TextEditingController();
  late final _day = TextEditingController();
  late final _hour = TextEditingController();
  late final _minute = TextEditingController();
  late final _second = TextEditingController();

  late final _fYear = FocusNode();
  late final _fMonth = FocusNode();
  late final _fDay = FocusNode();
  late final _fHour = FocusNode();
  late final _fMinute = FocusNode();
  late final _fSecond = FocusNode();

  bool _invalid = false;
  bool _isAm = true;
  Timer? _debounce;
  static const _debounceMs = 180; // tweak to taste (120–250 is common)
  bool _squelch = false; // NEW: guard against programmatic updates

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.value);

    for (final c in [_year, _month, _day, _hour, _minute, _second]) {
      c.addListener(_onAnyChanged);
    }
    for (final f in [_fYear, _fMonth, _fDay, _fHour, _fMinute, _fSecond]) {
      f.addListener(() {
        if (!f.hasFocus) _emitNow(); // commit on blur
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_year, _month, _day, _hour, _minute, _second]) {
      c.dispose();
    }
    for (final f in [_fYear, _fMonth, _fDay, _fHour, _fMinute, _fSecond]) {
      f.dispose();
    }
    super.dispose();
  }


  @override
  void didUpdateWidget(covariant DateTimeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _loadFrom(widget.value); // now safe; squelched
    }
  }

  void _loadFrom(DateTime? dt) {
    _squelch = true; // <— START suppressing
    try {
      if (dt == null) {
        _year.text = '';
        _month.text = '';
        _day.text = '';
        _hour.text = '';
        _minute.text = '';
        _second.text = '';
        _invalid = false;
        _isAm = true;
      } else {
        final local = dt;
        _year.text = local.year.toString().padLeft(4, '0');
        _month.text = local.month.toString().padLeft(2, '0');
        _day.text = local.day.toString().padLeft(2, '0');

        int h = local.hour;
        if (!widget.use24h) {
          _isAm = h < 12;
          h = h % 12;
          if (h == 0) h = 12;
        }
        _hour.text = h.toString().padLeft(2, '0');
        _minute.text = local.minute.toString().padLeft(2, '0');
        _second.text = local.second.toString().padLeft(2, '0');
        _invalid = false;
      }
    } finally {
      _squelch = false; // <— END suppressing
    }
    setState(() {}); // reflect UI changes, no parent callback
  }

  void _onAnyChanged() {
    if (_squelch) {
      _invalid = _tryParse() == null;
      setState(() {});
      return;
    }

    // keep your auto-advance immediate if you like
    _maybeAdvance(_year, 4, _fMonth);
    _maybeAdvance(_month, 2, _fDay);
    _maybeAdvance(_day, 2, _fHour);
    _maybeAdvance(_hour, 2, _fMinute);
    _maybeAdvance(_minute, 2, widget.includeSeconds ? _fSecond : null);
    if (widget.includeSeconds) _maybeAdvance(_second, 2, null);

    // debounce the expensive/propagating work
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), _emitNow);
  }

  void _maybeAdvance(TextEditingController c, int max, FocusNode? next) {
    if (c.text.length == max && next != null && next.canRequestFocus) {
      next.requestFocus();
    }
  }

  DateTime? _tryParse() {
    int? year = int.tryParse(_year.text);
    int? month = int.tryParse(_month.text);
    int? day = int.tryParse(_day.text);
    int? hour = int.tryParse(_hour.text);
    int? minute = int.tryParse(_minute.text);
    int? second = int.tryParse(_second.text.isEmpty ? '0' : _second.text);

    if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
      return null;
    }

    if (!widget.use24h) {
      if (hour < 1 || hour > 12) return null;
      if (_isAm) {
        hour = hour % 12;
      } else {
        hour = (hour % 12) + 12;
      }
    }

    if (widget.allowRollover) {
      // Normalize by constructing from an epoch and adding durations
      // (simple approach: clamp ranges then adjust using DateTime constructor which overflows months/days)
      try {
        final dt = DateTime(year, month, day, hour, minute, second);
        return dt;
      } catch (_) {
        return null;
      }
    } else {
      // Strict validation
      if (month < 1 || month > 12) return null;
      final daysInMonth = DateTime(year, month + 1, 0).day; // last day prev month
      if (day < 1 || day > daysInMonth) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;
      if (second < 0 || second > 59) return null;
      try {
        return DateTime(year, month, day, hour, minute, second);
      } catch (_) {
        return null;
      }
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    hintText: hint,
    errorText: _invalid ? '' : null,
    // Show red border when invalid
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget _numBox({
    required TextEditingController c,
    required FocusNode f,
    required String hint,
    required int maxLen,
    double width = 56,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: c,
        focusNode: f,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLen)],
        decoration: _dec(hint),
      ),
    );
  }

  bool _isMidToken() {
    if (_fMonth.hasFocus && _month.text.length == 1) return true;
    if (_fDay.hasFocus && _day.text.length == 1) return true;
    if (_fHour.hasFocus && _hour.text.length == 1) return true;
    if (_fMinute.hasFocus && _minute.text.length == 1) return true;
    if (widget.includeSeconds && _fSecond.hasFocus && _second.text.length == 1) return true;
    // Year usually 4 digits; treat partial year as mid-token too if you expose it:
    if (widget.useYear && _fYear.hasFocus && _year.text.length < 4) return true;
    return false;
  }

  void _emitNow() {
    if (_isMidToken()) return; // don't fire on partial "1" of "10"

    final parsed = _tryParse();
    setState(() => _invalid = parsed == null);

    // Only notify parent when we have a valid DateTime
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final label = widget.label;

    final dateRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.useYear) ...[
          _numBox(c: _year, f: _fYear, hint: 'YYYY', maxLen: 4, width: 72),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('/')),
        ],
        _numBox(c: _month, f: _fMonth, hint: 'MM', maxLen: 2),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('/')),
        _numBox(c: _day, f: _fDay, hint: 'DD', maxLen: 2),
        Spacer(),
        LightIconButton(
          tooltip: 'Open date picker',
          onPressed: () async {
            final now = DateTime.now();
            final current = _tryParse() ?? widget.value ?? now;
            final picked = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              // preserve time components
              final time = _tryParse() ?? current;
              final merged = DateTime(
                picked.year,
                picked.month,
                picked.day,
                time.hour,
                time.minute,
                widget.includeSeconds ? time.second : 0,
              );
              _loadFrom(merged);
              widget.onChanged?.call(merged);
            }
          },
          iconData: Icons.event,
        ),
      ],
    );

    final timeRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _numBox(c: _hour, f: _fHour, hint: widget.use24h ? 'HH' : 'hh', maxLen: 2),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':')),
        _numBox(c: _minute, f: _fMinute, hint: 'mm', maxLen: 2),
        if (widget.includeSeconds) ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':')),
          _numBox(c: _second, f: _fSecond, hint: 'ss', maxLen: 2),
        ],
        if (!widget.use24h) ...[
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [_isAm, !_isAm],
            onPressed: (i) {
              setState(() => _isAm = i == 0);
              _onAnyChanged();
            },
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('AM')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('PM')),
            ],
          ),
        ],
        Spacer(),
        LightIconButton(
          tooltip: 'Open time picker',
          onPressed: () async {
            final current = _tryParse() ?? widget.value ?? DateTime.now();
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(current),
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: widget.use24h),
                child: child!,
              ),
            );
            if (picked != null) {
              final merged = DateTime(
                current.year,
                current.month,
                current.day,
                picked.hour,
                picked.minute,
                widget.includeSeconds ? int.tryParse(_second.text) ?? 0 : 0,
              );
              _loadFrom(merged);
              widget.onChanged?.call(merged);
            }
          },
          iconData: Icons.access_time,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: t.textTheme.titleMedium),
          ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            dateRow,
            timeRow,
            if (_invalid) Text('Invalid date/time', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.error)),
          ],
        ),
      ],
    );
  }
}
