import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsolar/models/event_model.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/widgets/event_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Power',
    'Relay',
    'System',
    'Connection',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Row(
                  children: [
                    Icon(
                      _selectedFilter == filter
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 18,
                      color: _selectedFilter == filter
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(filter),
                  ],
                ),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_selectedFilter, style: const TextStyle(fontSize: 14)),
                  const Icon(Icons.filter_list, size: 18),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClearHistory(),
          ),
        ],
      ),
      body: Consumer<EnergyProvider>(
        builder: (context, provider, _) {
          final events = provider.events;

          if (events.isEmpty) {
            return _buildEmptyState();
          }

          // Parse events to EventModel objects
          final eventModels = events.map((e) {
            if (e is Map<String, dynamic>) {
              return EventModel.fromJson(e);
            }
            return EventModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: EventType.info,
              category: EventCategory.system,
              message: e.toString(),
              details: '',
              timestamp: DateTime.now(),
            );
          }).toList();

          // Apply filter
          final filteredEvents = _applyFilter(eventModels);

          if (filteredEvents.isEmpty) {
            return _buildNoResultsState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return EventTile(
                  event: event,
                  onTap: () => _showEventDetails(event),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<EventModel> _applyFilter(List<EventModel> events) {
    if (_selectedFilter == 'All') return events;

    final categoryMap = {
      'Power': EventCategory.power,
      'Relay': EventCategory.relay,
      'System': EventCategory.system,
      'Connection': EventCategory.connection,
    };

    final targetCategory = categoryMap[_selectedFilter];
    if (targetCategory == null) return events;

    return events.where((e) => e.category == targetCategory).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System events will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No events match filter',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _selectedFilter = 'All'),
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                event.message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (event.details.isNotEmpty) ...[
                Text(
                  event.details,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Category', event.categoryDisplayName),
              _buildDetailRow('Source', event.sourceDisplayName),
              _buildDetailRow('Time', event.formattedDateTime),
              _buildDetailRow('Type', event.type.name.toUpperCase()),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all event history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<EnergyProvider>(
                context,
                listen: false,
              );
              provider.clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
