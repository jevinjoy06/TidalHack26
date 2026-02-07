import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class RichCard extends StatelessWidget {
  final String cardType;
  final Map<String, dynamic> data;

  const RichCard({
    super.key,
    required this.cardType,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    switch (cardType) {
      case 'task_card':
        return _buildTaskCard(isDark);
      case 'email_card':
        return _buildEmailCard(isDark);
      case 'flight_card':
        return _buildFlightCard(isDark);
      case 'bill_card':
        return _buildBillCard(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardContainer(bool isDark, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildTaskCard(bool isDark) {
    final title = data['title'] ?? 'Untitled Task';
    final status = data['status'] ?? 'pending';
    final priority = data['priority'] ?? 'medium';
    final dueDate = data['due_date'];

    final priorityColor = switch (priority) {
      'urgent' => AppTheme.error,
      'high' => AppTheme.warning,
      'medium' => AppTheme.primaryMaroon,
      _ => (isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
    };

    final isCompleted = status == 'completed';

    return _buildCardContainer(isDark, children: [
      Row(
        children: [
          Icon(
            isCompleted
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            size: 20,
            color: isCompleted ? AppTheme.success : priorityColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
      if (dueDate != null) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 28),
            Icon(CupertinoIcons.calendar, size: 12, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              dueDate.toString(),
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    ]);
  }

  Widget _buildEmailCard(bool isDark) {
    final from = data['from'] ?? 'Unknown';
    final subject = data['subject'] ?? 'No subject';
    final preview = data['preview'] ?? '';
    final isUnread = data['unread'] ?? false;

    return _buildCardContainer(isDark, children: [
      Row(
        children: [
          Icon(
            isUnread
                ? CupertinoIcons.envelope_badge_fill
                : CupertinoIcons.envelope,
            size: 20,
            color: isUnread ? AppTheme.primaryMaroon : (isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              from,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Text(
          subject,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (preview.isNotEmpty) ...[
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            preview,
            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ]);
  }

  Widget _buildFlightCard(bool isDark) {
    final airline = data['airline'] ?? '';
    final flightNumber = data['flight_number'] ?? '';
    final departure = data['departure'] ?? '';
    final arrival = data['arrival'] ?? '';
    final departureTime = data['departure_time'] ?? '';
    final arrivalTime = data['arrival_time'] ?? '';
    final status = data['status'] ?? '';

    final statusColor = switch (status.toString().toLowerCase()) {
      'on time' => AppTheme.success,
      'delayed' => AppTheme.warning,
      'cancelled' => AppTheme.error,
      _ => (isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
    };

    return _buildCardContainer(isDark, children: [
      Row(
        children: [
          Icon(CupertinoIcons.airplane, size: 18, color: AppTheme.primaryMaroon),
          const SizedBox(width: 8),
          Text(
            '$airline $flightNumber',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const Spacer(),
          if (status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const SizedBox(width: 26),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(departure, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                Text(departureTime, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(CupertinoIcons.arrow_right, size: 14, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(arrival, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? CupertinoColors.white : CupertinoColors.black)),
                Text(arrivalTime, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textTertiary : AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildBillCard(bool isDark) {
    final name = data['name'] ?? '';
    final amount = data['amount'] ?? 0;
    final frequency = data['frequency'] ?? 'monthly';
    final nextDue = data['next_due'] ?? '';

    return _buildCardContainer(isDark, children: [
      Row(
        children: [
          Icon(CupertinoIcons.creditcard, size: 18, color: AppTheme.primaryMaroon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          Text(
            '\$$amount',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          const SizedBox(width: 26),
          Text(
            frequency,
            style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
          ),
          if (nextDue.isNotEmpty) ...[
            const SizedBox(width: 12),
            Icon(CupertinoIcons.calendar, size: 12, color: AppTheme.systemGray),
            const SizedBox(width: 4),
            Text(
              'Due: $nextDue',
              style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
            ),
          ],
        ],
      ),
    ]);
  }
}
