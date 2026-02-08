import 'package:intl/intl.dart';

String getRelativeTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  // < 1 minute
  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  // < 1 hour
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }

  // < 24 hours
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }

  // Yesterday
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
  if (timestampDate.isAtSameMomentAs(yesterday)) {
    return 'Yesterday';
  }

  // < 7 days
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  // < 1 year
  if (difference.inDays < 365) {
    return DateFormat('MMM d').format(timestamp);
  }

  // >= 1 year
  return DateFormat('MMM d, yyyy').format(timestamp);
}
