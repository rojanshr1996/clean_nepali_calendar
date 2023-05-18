part of clean_nepali_calendar;

typedef HeaderDayBuilder = Widget Function(String headerName, int dayNumber);
const double _kDayPickerRowHeight = 52.0;

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const columnCount = 7;
    final tileWidth = constraints.crossAxisExtent / columnCount;
    final tileHeight =
        math.min(_kDayPickerRowHeight, constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

class _DaysView<T> extends StatelessWidget {
  _DaysView({
    Key? key,
    required this.selectedDate,
    required this.currentDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    required this.language,
    required this.calendarStyle,
    required this.headerStyle,
    required this.eventLoader,
    this.selectableDayPredicate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.headerDayType = HeaderDayType.initial,
    this.headerDayBuilder,
    this.eventMarkerBuilder,
    this.dateCellBuilder,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate)),
        super(key: key);

  final NepaliDateTime selectedDate;

  final NepaliDateTime currentDate;

  final ValueChanged<NepaliDateTime> onChanged;

  final NepaliDateTime firstDate;

  final NepaliDateTime lastDate;

  final NepaliDateTime displayedMonth;

  final SelectableDayPredicate? selectableDayPredicate;

  final DragStartBehavior dragStartBehavior;

  final Language language;
  final CalendarStyle calendarStyle;
  final HeaderStyle headerStyle;
  final HeaderDayType headerDayType;
  final HeaderDayBuilder? headerDayBuilder;
  final EventMarkerBuilder? eventMarkerBuilder;
  final DateCellBuilder? dateCellBuilder;

  /// Function that assigns a list of events to a specified day.
  final List<T> Function(NepaliDateTime day)? eventLoader;

  List<Widget> _getDayHeaders(
      Language language, TextStyle? headerStyle, HeaderDayType headerDayType, HeaderDayBuilder? builder) {
    List<String> headers;
    switch (headerDayType) {
      case HeaderDayType.fullName:
        {
          headers = (language == Language.english) ? dayHeaderFullNameEnglish : dayHeaderFullNameNepali;
          break;
        }
      case HeaderDayType.halfName:
        {
          headers = (language == Language.english) ? dayHeaderHalfNameEnglish : dayHeaderHalfNameNepali;

          break;
        }
      case HeaderDayType.initial:
        {
          headers = (language == Language.english) ? dayHeaderLetterEnglish : dayHeaderLetterNepali;

          break;
        }
    }
    return headers
        .asMap()
        .entries
        .map(
          (label) => ExcludeSemantics(
            child: builder != null
                ? builder(label.value, label.key)
                : Center(
                    child: Text(
                      label.value,
                      style: headerStyle?.copyWith(
                        color: label.key == 6 ? calendarStyle.weekEndTextColor : headerStyle.color,
                      ),
                    ),
                  ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = displayedMonth.totalDays;
    final firstDayOffset = displayedMonth.weekday - 1;
    final labels = <Widget>[];
    if (calendarStyle.renderDaysOfWeek) {
      labels.addAll(
        _getDayHeaders(language, themeData.textTheme.bodySmall, headerDayType, headerDayBuilder),
      );
    }
    //this weekNumber is to determine the weekend, saturday.
    int weekNumber = 0;
    for (var i = 0; true; i += 1) {
      if (weekNumber > 6) weekNumber = 0;
      // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
      // a leap year.
      final day = i - firstDayOffset + 1;
      if (day > daysInMonth) break;
      if (day < 1) {
        labels.add(Container());
      } else {
        final dayToBuild = NepaliDateTime(year, month, day);
        final events = eventLoader?.call(dayToBuild) ?? [];

        final disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null && !selectableDayPredicate!(dayToBuild));

        final isSelectedDay = selectedDate.year == year && selectedDate.month == month && selectedDate.day == day;
        final bool isCurrentDay = currentDate.year == year && currentDate.month == month && currentDate.day == day;
        final semanticLabel = '${formattedMonth(month, Language.english)} $day, $year';
        final text = '${language == Language.english ? day : NepaliUnicode.convert('$day')}';

        Widget dayWidget = Stack(
          children: [
            _DayWidget(
              isDisabled: disabled,
              text: text,
              label: semanticLabel,
              isToday: isCurrentDay,
              isSelected: isSelectedDay,
              calendarStyle: calendarStyle,
              day: dayToBuild,
              isWeekend: weekNumber == 6,
              onTap: () {
                onChanged(dayToBuild);
              },
              builder: dateCellBuilder,
            ),
            events.isNotEmpty
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: eventMarkerBuilder?.call(events, dayToBuild) ??
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events
                                .take(1)
                                .map<Widget>(
                                  (event) => _buildSingleMarker(dayToBuild, event, 6),
                                )
                                .toList(),
                          ),
                        ),
                  )
                : const SizedBox.shrink(),
          ],
        );

        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              onChanged(dayToBuild);
            },
            dragStartBehavior: dragStartBehavior,
            child: dayWidget,
          );
        }
        labels.add(dayWidget);
      }

      weekNumber += 1;
    }

    return Column(
      children: <Widget>[
        Flexible(
          child: GridView.custom(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _kDayPickerGridDelegate,
            childrenDelegate: SliverChildListDelegate(labels, addRepaintBoundaries: false),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleMarker(DateTime day, T event, double markerSize) {
    return Container(
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: calendarStyle.todayColor,
      ),
    );
  }
}

final List<String> dayHeaderFullNameEnglish = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday"
];
final List<String> dayHeaderFullNameNepali = ["आइतबार", "सोमबार", "मंगलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"];
final List<String> dayHeaderHalfNameEnglish = ["Sun", "Mon", "Tues", "Wed", "Thu", "Fri", "Sat"];
final List<String> dayHeaderHalfNameNepali = ["आइत", "सोम", "मंगल", "बुध", "बिही", "शुक्र", "शनि"];

final List<String> dayHeaderLetterEnglish = [
  'S',
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
];

final List<String> dayHeaderLetterNepali = [
  'आ',
  'सो',
  'मं',
  'बु',
  'वि',
  'शु',
  'श',
];
