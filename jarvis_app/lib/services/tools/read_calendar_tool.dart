import 'package:googleapis/calendar/v3.dart' as calendar;

import 'google_docs_tool.dart';
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
  final client = await getAuthenticatedClient();
  if (client == null) {
    return 'Error: Please sign in with Google first (Settings > Sign in with Google).';
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

  try {
    final calendarApi = calendar.CalendarApi(client);
    final eventsResponse = await calendarApi.events.list(
      'primary',
      timeMin: start.toUtc(),
      timeMax: end.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 30,
    );

    final items = eventsResponse.items;
    if (items == null || items.isEmpty) {
      return 'No events found between ${start.toIso8601String().split('T')[0]} and ${end.toIso8601String().split('T')[0]}.';
    }

    final sb = StringBuffer();
    for (var i = 0; i < items.length && i < 10; i++) {
      final e = items[i];
      final title = e.summary ?? 'Untitled';
      final startDt = e.start?.dateTime;
      final startDate = e.start?.date;
      final startStr = startDt != null
          ? startDt.toIso8601String().split('.')[0]
          : (startDate ?? '');
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
