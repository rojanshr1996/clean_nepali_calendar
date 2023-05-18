part of clean_nepali_calendar;

typedef TextBuilder = String Function(NepaliDateTime date, Language language);
typedef HeaderGestureCallback = void Function(NepaliDateTime focusedDay);

String formattedMonth(
  int month, [
  Language? language,
]) =>
    NepaliDateFormat.MMMM(language).format(
      NepaliDateTime(1970, month),
    );

const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight = _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

class CleanNepaliCalendar<T> extends StatefulWidget {
  const CleanNepaliCalendar({
    Key? key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.language = Language.nepali,
    this.onDaySelected,
    this.headerStyle = const HeaderStyle(),
    this.calendarStyle = const CalendarStyle(),
    this.onHeaderTapped,
    this.onHeaderLongPressed,
    required this.controller,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.dateCellBuilder,
    this.enableVibration = true,
    this.headerBuilder,
    this.eventMarkerBuilder,
    this.eventLoader,
  }) : super(key: key);

  final NepaliDateTime? initialDate;
  final NepaliDateTime? firstDate;
  final NepaliDateTime? lastDate;
  final Function(NepaliDateTime)? onDaySelected;
  final SelectableDayPredicate? selectableDayPredicate;
  final Language language;
  final CalendarStyle calendarStyle;
  final HeaderStyle headerStyle;
  final HeaderGestureCallback? onHeaderTapped;
  final HeaderGestureCallback? onHeaderLongPressed;
  final NepaliCalendarController controller;
  final HeaderDayType headerDayType;
  final HeaderDayBuilder? headerDayBuilder;
  final DateCellBuilder? dateCellBuilder;
  final HeaderBuilder? headerBuilder;
  final EventMarkerBuilder? eventMarkerBuilder;
  final bool enableVibration;

  /// Function that assigns a list of events to a specified day.
  final List<T> Function(NepaliDateTime day)? eventLoader;

  @override
  CleanNepaliCalendarState<T> createState() => CleanNepaliCalendarState<T>();
}

class CleanNepaliCalendarState<T> extends State<CleanNepaliCalendar<T>> {
  late ValueNotifier<NepaliDateTime> _selectedDate;
  @override
  void initState() {
    super.initState();
    _selectedDate = ValueNotifier<NepaliDateTime>(widget.initialDate ?? NepaliDateTime.now());
    widget.controller._init(
      selectedDayCallback: _handleDayChanged,
      initialDay: widget.initialDate ?? NepaliDateTime.now(),
    );
  }

  bool _announcedInitialDate = false;

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        NepaliDateFormat.yMMMMd().format(_selectedDate.value),
        textDirection,
      );
    }
  }

  @override
  void didUpdateWidget(CleanNepaliCalendar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedDate.value = widget.initialDate ?? NepaliDateTime.now();
    widget.controller.setSelectedDay(widget.initialDate ?? NepaliDateTime.now());
  }

  final GlobalKey _pickerKey = GlobalKey();

  void _vibrate() {
    HapticFeedback.vibrate();
  }

  void _handleDayChanged(NepaliDateTime value, {bool runCallback = true}) {
    if (widget.enableVibration) _vibrate();

    widget.controller.setSelectedDay(value, isProgrammatic: false);
    _selectedDate.value = value;

    if (runCallback && widget.onDaySelected != null) {
      widget.onDaySelected!(value);
    }
  }

  Widget _buildPicker() {
    return ValueListenableBuilder(
        valueListenable: _selectedDate,
        builder: (BuildContext context, NepaliDateTime value, Widget? child) {
          return _MonthView(
            key: _pickerKey,
            headerStyle: widget.headerStyle,
            calendarStyle: widget.calendarStyle,
            language: widget.language,
            selectedDate: _selectedDate.value,
            onChanged: _handleDayChanged,
            firstDate: widget.firstDate ?? NepaliDateTime(2000, 1),
            lastDate: widget.lastDate ?? NepaliDateTime(2095, 12),
            selectableDayPredicate: widget.selectableDayPredicate,
            onHeaderTapped: widget.onHeaderTapped,
            onHeaderLongPressed: widget.onHeaderLongPressed,
            headerDayType: widget.headerDayType,
            headerDayBuilder: widget.headerDayBuilder,
            dateCellBuilder: widget.dateCellBuilder,
            headerBuilder: widget.headerBuilder,
            dragStartBehavior: DragStartBehavior.start,
            eventLoader: widget.eventLoader,
            eventMarkerBuilder: widget.eventMarkerBuilder,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return _buildPicker();
  }
}

typedef SelectableDayPredicate = bool Function(NepaliDateTime day);
