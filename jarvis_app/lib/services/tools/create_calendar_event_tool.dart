import 'package:googleapis/calendar/v3.dart' as calendar;

import 'google_docs_tool.dart';
import 'tool_registry.dart';

const createCalendarEventSchema = {
  'type': 'function',
  'function': {
    'name': 'create_calendar_event',
    'description':
        "Create an event on the user's Google Calendar. Use when the user asks to add, schedule, or block time (meeting, reminder, focus time, etc.).",
    'parameters': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': 'Event title/summary'},
        'start': {
          'type': 'string',
          'description':
              'Start time in ISO 8601 format (e.g. 2025-02-10T14:00:00). For all-day use date only: 2025-02-10',
        },
        'end': {
          'type': 'string',
          'description': 'End time in ISO 8601. Omit if using duration_minutes',
        },
        'duration_minutes': {
          'type': 'integer',
          'description': 'Duration in minutes when end is not provided (e.g. 60). Ignored if end is provided',
        },
        'description': {'type': 'string', 'description': 'Event description'},
        'location': {'type': 'string', 'description': 'Event location (e.g. address or room)'},
      },
      'required': ['title', 'start'],
    },
  },
};

const int _defaultDurationMinutes = 60;

/// Returns true if [s] looks like date-only (no time part).
bool _isDateOnly(String s) {
  final trimmed = s.trim();
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed);
}

/// Parse [s] as DateTime. Returns null on failure.
DateTime? _parseDateTime(String s) {
  if (s.trim().isEmpty) return null;
  return DateTime.tryParse(s.trim());
}

Future<String> createCalendarEventExecutor(Map<String, dynamic> args) async {
  final client = await getAuthenticatedClient();
  if (client == null) {
    return 'Error: Please sign in with Google first (Settings > Sign in with Google).';
  }

  final title = (args['title'] ?? '').toString().trim();
  if (title.isEmpty) return 'Error: title is required.';

  final startStr = (args['start'] ?? '').toString().trim();
  if (startStr.isEmpty) return 'Error: start is required.';

  final endStr = args['end']?.toString().trim();
  final durationMinutes = args['duration_minutes'];
  final description = args['description']?.toString().trim();
  final location = args['location']?.toString().trim();

  final isAllDay = _isDateOnly(startStr);
  DateTime? startDt = _parseDateTime(startStr);
  if (startDt == null) {
    return 'Error: start must be a valid ISO 8601 date or date-time (e.g. 2025-02-10 or 2025-02-10T14:00:00).';
  }

  DateTime? endDt;
  if (endStr != null && endStr.isNotEmpty) {
    endDt = _parseDateTime(endStr);
    if (endDt == null) {
      return 'Error: end must be a valid ISO 8601 date or date-time.';
    }
  } else if (durationMinutes != null) {
    final mins = durationMinutes is int ? durationMinutes : int.tryParse(durationMinutes.toString());
    if (mins != null && mins > 0) {
      endDt = startDt.add(Duration(minutes: mins));
    }
  }
  if (endDt == null) {
    if (isAllDay) {
      endDt = startDt.add(const Duration(days: 1));
    } else {
      endDt = startDt.add(const Duration(minutes: _defaultDurationMinutes));
    }
  }
  if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
    return 'Error: end must be after start.';
  }

  try {
    calendar.EventDateTime startEdt;
    calendar.EventDateTime endEdt;
    if (isAllDay) {
      startEdt = calendar.EventDateTime(date: startDt);
      endEdt = calendar.EventDateTime(date: endDt);
    } else {
      startEdt = calendar.EventDateTime(dateTime: startDt);
      endEdt = calendar.EventDateTime(dateTime: endDt);
    }

    final event = calendar.Event(
      summary: title,
      start: startEdt,
      end: endEdt,
      description: description?.isNotEmpty == true ? description : null,
      location: location?.isNotEmpty == true ? location : null,
    );

    final calendarApi = calendar.CalendarApi(client);
    final created = await calendarApi.events.insert(event, 'primary');

    final link = created.htmlLink ?? '';
    final linkHint = link.isNotEmpty ? ' Call open_url with $link so the user can view it.' : '';
    return "Created event '$title' on ${startStr}.$linkHint";
  } catch (e) {
    return 'Error: $e';
  }
}

void registerCreateCalendarEventTool(ToolRegistry registry) {
  registry.register('create_calendar_event', createCalendarEventSchema, createCalendarEventExecutor);
}
