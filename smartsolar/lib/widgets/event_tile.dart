import 'package:flutter/material.dart';

import 'package:smartsolar/models/event_model.dart';

class EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventTile({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getEventColor().withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getEventColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEventColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEventIcon(),
                color: _getEventColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getEventColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.categoryDisplayName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getEventColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.details.isNotEmpty
                              ? event.details
                              : 'No details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor() {
    switch (event.type) {
      case EventType.info:
        return Colors.blue;
      case EventType.success:
        return Colors.green;
      case EventType.warning:
        return Colors.orange;
      case EventType.danger:
        return Colors.red;
    }
  }

  IconData _getEventIcon() {
    switch (event.category) {
      case EventCategory.system:
        return Icons.settings;
      case EventCategory.power:
        return Icons.electrical_services;
      case EventCategory.relay:
        return Icons.power;
      case EventCategory.mode:
        return Icons.tune;
      case EventCategory.command:
        return Icons.terminal;
      case EventCategory.sensor:
        return Icons.sensors;
      case EventCategory.connection:
        return Icons.wifi;
      case EventCategory.alert:
        return Icons.warning;
    }
  }
}
