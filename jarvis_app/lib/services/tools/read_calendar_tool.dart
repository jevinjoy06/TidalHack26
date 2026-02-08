import 'package:calendar_bridge/calendar_bridge.dart';

import '../../config/secrets.dart';
import 'tool_registry.dart';

const readCalendarSchema = {
  'type': 'function',
  'function': {
    'name': 'read_calendar',
    'description': 'Read calendar events. Find dates like "next Thursday" or list events in a date range. Use to check when events are scheduled.',
    'parameters': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'e.g. "next Thursday", "events this week", "what day is the 15th"'},
      },
      'required': ['query'],
    },
  },
};

Future<String> readCalendarExecutor(Map<String, dynamic> args) async {
  try {
    final bridge = CalendarBridge();
    final hasPermission = await bridge.hasPermissions();
    if (hasPermission != PermissionStatus.granted) {
      final granted = await bridge.requestPermissions();
      if (!granted) {
        return 'Calendar access not granted. Please allow in System Settings > Privacy > Calendars.';
      }
    }

    final query = (args['query'] ?? '').toString().toLowerCase();
    final now = DateTime.now();

    DateTime start = now;
    DateTime end = now.add(const Duration(days: 14));
    if (query.contains('next')) {
      const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      for (var i = 0; i < 7; i++) {
        final d = now.add(Duration(days: i + 1));
        final dayName = weekdays[d.weekday - 1];
        if (query.contains(dayName)) {
          start = DateTime(d.year, d.month, d.day);
          end = start.add(const Duration(days: 1));
          break;
        }
      }
    } else if (query.contains('this week')) {
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day - (weekday - 1));
      end = start.add(const Duration(days: 7));
    }

    final calendars = await bridge.getCalendars();
    if (calendars.isEmpty) return 'No calendars found.';

    final events = <CalendarEvent>[];
    for (final cal in calendars) {
      final evts = await bridge.getEvents(cal.id, startDate: start, endDate: end);
      events.addAll(evts);
    }

    if (events.isEmpty) {
      return 'No events found between ${start.toIso8601String().split('T')[0]} and ${end.toIso8601String().split('T')[0]}.';
    }

    final sb = StringBuffer();
    for (var i = 0; i < events.length && i < 10; i++) {
      final e = events[i];
      final title = e.title ?? 'Untitled';
      final startStr = e.start?.toString().split('.')[0] ?? '';
      sb.writeln('- $title ($startStr)');
    }
    return sb.toString().trim();
  } catch (e) {
    return 'Error: $e';
  }
}

void registerReadCalendarTool(ToolRegistry registry) {
  registry.register('read_calendar', readCalendarSchema, readCalendarExecutor);
}
