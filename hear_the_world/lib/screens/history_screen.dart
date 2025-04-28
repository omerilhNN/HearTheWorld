import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../services/accessibility_service.dart';
import '../utils/app_theme.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Mock data for history - in a real app, this would come from storage
  final List<ChatSession> _historySessions = [
    ChatSession(
      id: '1',
      summary: 'Objects on desk: pen, notebook, coffee mug',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      messages: [],
    ),
    ChatSession(
      id: '2',
      summary: 'Kitchen items: plate with sandwich, apple, glass of water',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      messages: [],
    ),
    ChatSession(
      id: '3',
      summary: 'Living room: TV remote, books on shelf, reading glasses',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      messages: [],
    ),
    ChatSession(
      id: '4',
      summary: 'Bathroom counter: toothbrush, toothpaste, face towel, soap',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      messages: [],
    ),
    ChatSession(
      id: '5',
      summary: 'Dinner table: pasta dish, salad bowl, wine glass, water jug',
      timestamp: DateTime.now().subtract(const Duration(days: 10)),
      messages: [],
    ),
  ];

  // Filter parameters
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchText = '';

  List<ChatSession> get _filteredSessions {
    return _historySessions.where((session) {
      // Apply date filter
      if (_startDate != null && session.timestamp.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && session.timestamp.isAfter(_endDate!)) {
        return false;
      }

      // Apply search filter
      if (_searchText.isNotEmpty &&
          !session.summary.toLowerCase().contains(_searchText.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Announce screen for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityService().speak(
        'History screen. Showing your past chat sessions. Swipe up and down to browse.',
      );
    });
  }

  void _handleTabChange(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        // Already on history screen
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Sessions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date range picker buttons
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    _startDate == null
                        ? 'Not set'
                        : DateFormat('MMM dd, yyyy').format(_startDate!),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    _endDate == null
                        ? 'Not set'
                        : DateFormat('MMM dd, yyyy').format(_endDate!),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search in summaries',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _searchText = '';
                  });
                  Navigator.of(context).pop();
                  AccessibilityService().speak('Filters cleared');
                },
                child: const Text('CLEAR'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AccessibilityService().speak('Filters applied');
                },
                child: const Text('APPLY'),
              ),
            ],
          ),
    );
  }

  void _openSessionDetail(ChatSession session) {
    // Show session details in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session Details',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date and time
                    Text(
                      session.formattedDate,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.smallTextSize,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.summary,
                      style: TextStyle(fontSize: AppTheme.regularTextSize),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            AccessibilityService().speak(session.summary);
                          },
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Play Audio'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            AccessibilityService().speak(
                              'View image feature not implemented in this demo',
                            );
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('View Image'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update the navigation controller to reflect current screen
    final navigationController = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    navigationController.changeIndex(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
            AccessibilityService().speak('Back to home screen');
          },
          tooltip: 'Back to home',
        ),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter history',
          ),
        ],
      ),
      body:
          _filteredSessions.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No history found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchText.isNotEmpty ||
                              _startDate != null ||
                              _endDate != null
                          ? 'Try adjusting your filters'
                          : 'Start a new chat to see history',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _filteredSessions.length,
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  final session = _filteredSessions[index];
                  return Semantics(
                    button: true,
                    label:
                        'Chat session from ${session.formattedDate}. Summary: ${session.summary}. Double tap to open details.',
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        title: Text(
                          DateFormat('MMM d').format(session.timestamp) +
                              ' – ' +
                              session.summary.split('\n').first,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: AppTheme.regularTextSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('HH:mm').format(session.timestamp),
                            style: TextStyle(
                              fontSize: AppTheme.smallTextSize,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openSessionDetail(session),
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: AccessibleBottomNav(onTabChanged: _handleTabChange),
    );
  }
}
