import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/alarm_provider.dart';
import '../widgets/alarm_card.dart';
import '../widgets/add_alarm_bottom_sheet.dart';
import 'settings_screen.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientDecoration(colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              // Header with title and settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alarm',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Date and time display card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: colorScheme.primaryContainer,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Clock icon in top-right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.access_time_outlined,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        // Time and date centered
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Time
                              Text(
                                timeFormat.format(now),
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Date underneath
                              Text(
                                dateFormat.format(now),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Alarm list
              Expanded(
                child: Consumer<AlarmProvider>(
                  builder: (context, alarmProvider, child) {
                    if (alarmProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final alarms = alarmProvider.alarms;

                    if (alarms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.alarm_off_outlined,
                              size: 80,
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No alarms set',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first alarm',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => alarmProvider.loadAlarms(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alarms.length,
                        itemBuilder: (context, index) {
                          final alarm = alarms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AlarmCard(
                              alarm: alarm,
                              onToggle: (value) {
                                alarmProvider.toggleAlarm(alarm.id, value);
                              },
                              onEdit: () {
                                _showAddAlarmBottomSheet(context, alarm);
                              },
                              onDelete: () {
                                _showDeleteDialog(context, alarmProvider, alarm.id);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAlarmBottomSheet(context, null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAlarmBottomSheet(BuildContext context, alarm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmBottomSheet(alarm: alarm),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AlarmProvider provider,
    String alarmId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: const Text('Are you sure you want to delete this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteAlarm(alarmId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
