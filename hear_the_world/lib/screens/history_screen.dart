import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chat_models.dart';
import '../services/accessibility_service.dart';
import '../services/session_manager.dart';
import '../utils/app_theme.dart';
import '../widgets/accessible_bottom_nav.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // We'll use SessionManager instead of local mock data

  // Filter parameters
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchText = '';

  // Ses çalma durumunu izleyen değişken
  int? _playingSessionId;
  List<ChatSession> _filteredSessions(List<ChatSession> sessions) {
    return sessions.where((session) {
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
        context.go('/forum');
        break;
      case 3:
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
                    const SizedBox(height: 24), // Centered Play Audio button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AccessibilityService().speak(session.summary);
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Play Audio'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
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

  // Sesli anlatımı başlatma/durdurma
  void _toggleAudio(ChatSession session) {
    setState(() {
      if (_playingSessionId == int.tryParse(session.id)) {
        // Eğer bu session zaten çalıyorsa, durdur
        _playingSessionId = null;
        AccessibilityService().stopSpeaking();
        AccessibilityService().speak('Audio stopped');
      } else {
        // Yeni sesli anlatımı başlat
        _playingSessionId = int.tryParse(session.id);
        AccessibilityService().speak(session.summary);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update the navigation controller to reflect current screen
    final navigationController = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    navigationController.changeIndex(1);

    return Consumer<SessionManager>(
      builder: (context, sessionManager, _) {
        final sessions = sessionManager.sessions;
        final filteredSessions = _filteredSessions(sessions);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Previous Prompts'),
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
              filteredSessions.isEmpty
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
                  : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredSessions.length,
                            separatorBuilder:
                                (context, index) =>
                                    const SizedBox(height: 12.0),
                            padding: const EdgeInsets.all(4.0),
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              final bool isPlaying =
                                  _playingSessionId == int.tryParse(session.id);

                              return Semantics(
                                button: true,
                                label:
                                    'Chat session from ${session.formattedDate}. Summary: ${session.summary}. Double tap to open details.',
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 2.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openSessionDetail(session),
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Tarih başlığı
                                                  Text(
                                                    DateFormat(
                                                      'MMM dd, yyyy',
                                                    ).format(session.timestamp),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppTheme
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                  // Saat gösterimi
                                                  Text(
                                                    DateFormat(
                                                      'HH:mm',
                                                    ).format(session.timestamp),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          AppTheme
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Ana içerik
                                              Text(
                                                session.summary,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ), // Alt kısım - ses butonu, detay butonu, ve ayarlar butonu
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  bottomLeft: Radius.circular(
                                                    12.0,
                                                  ),
                                                  bottomRight: Radius.circular(
                                                    12.0,
                                                  ),
                                                ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Ses butonu
                                              IconButton(
                                                onPressed:
                                                    () => _toggleAudio(session),
                                                icon: Icon(
                                                  isPlaying
                                                      ? Icons.stop
                                                      : Icons.volume_up,
                                                  color:
                                                      isPlaying
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey
                                                              .shade700,
                                                ),
                                                tooltip:
                                                    isPlaying
                                                        ? 'Stop audio'
                                                        : 'Play audio',
                                              ),
                                              // Center placeholder
                                              TextButton.icon(
                                                onPressed:
                                                    () => _openSessionDetail(
                                                      session,
                                                    ),
                                                icon: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                                label: const Text('Details'),
                                              ),
                                              // Settings button on the right
                                              IconButton(
                                                onPressed: () {
                                                  context.go('/settings');
                                                  AccessibilityService().speak(
                                                    'Going to settings screen',
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.settings,
                                                  color: Colors.grey.shade700,
                                                ),
                                                tooltip: 'Go to settings',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          bottomNavigationBar: AccessibleBottomNav(
            onTabChanged: _handleTabChange,
          ),
        );
      },
    );
  }
}
