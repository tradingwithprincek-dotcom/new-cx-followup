import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../domain/follow_up.dart';
import 'follow_up_card.dart';

class FollowUpCalendarView extends StatefulWidget {
  const FollowUpCalendarView({
    super.key,
    required this.followUps,
    required this.onTapFollowUp,
    this.onComplete,
  });

  final List<FollowUp> followUps;
  final ValueChanged<FollowUp> onTapFollowUp;
  final ValueChanged<FollowUp>? onComplete;

  @override
  State<FollowUpCalendarView> createState() => _FollowUpCalendarViewState();
}

class _FollowUpCalendarViewState extends State<FollowUpCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<FollowUp>> get _byDay {
    final map = <DateTime, List<FollowUp>>{};
    for (final f in widget.followUps) {
      final key = _dayKey(f.reminderAt);
      map.putIfAbsent(key, () => []).add(f);
    }
    return map;
  }

  List<FollowUp> _eventsForDay(DateTime day) => _byDay[_dayKey(day)] ?? [];

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _eventsForDay(_selectedDay)
      ..sort((a, b) => a.reminderAt.compareTo(b.reminderAt));

    return Column(
      children: [
        TableCalendar<FollowUp>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _eventsForDay,
          calendarFormat: CalendarFormat.month,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => _focusedDay = focused,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(color: Color(0xFFF6B24F), shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(child: Text('No follow-ups on this day.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final followUp = selectedEvents[i];
                    return FollowUpCard(
                      followUp: followUp,
                      onTap: () => widget.onTapFollowUp(followUp),
                      onComplete: widget.onComplete == null ? null : () => widget.onComplete!(followUp),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
