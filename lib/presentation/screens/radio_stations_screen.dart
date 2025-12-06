import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/audio_player_service.dart';
import '../../data/models/radio_station.dart';
import '../providers/radio_station_provider.dart';

class RadioStationsScreen extends StatefulWidget {
  const RadioStationsScreen({super.key});

  @override
  State<RadioStationsScreen> createState() => _RadioStationsScreenState();
}

class _RadioStationsScreenState extends State<RadioStationsScreen> {
  String? _testingStationId;

  Future<void> _testStation(RadioStation station) async {
    if (_testingStationId == station.id) {
      // Stop testing
      await AudioPlayerService().stop();
      setState(() {
        _testingStationId = null;
      });
    } else {
      // Start testing
      if (_testingStationId != null) {
        // Stop previous test
        await AudioPlayerService().stop();
      }

      setState(() {
        _testingStationId = station.id;
      });

      try {
        await AudioPlayerService().play(station.streamUrl, 0.5);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing ${station.name}...'),
              action: SnackBarAction(
                label: 'Stop',
                onPressed: () async {
                  await AudioPlayerService().stop();
                  if (mounted) {
                    setState(() {
                      _testingStationId = null;
                    });
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _testingStationId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing station: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Stop any playing test when leaving the screen
    AudioPlayerService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Radio Stations')),
      body: Consumer<RadioStationProvider>(
        builder: (context, provider, _) {
          final stations = provider.stations;
          if (stations.isEmpty) {
            return const Center(
              child: Text('No stations added yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              final isTesting = _testingStationId == station.id;
              return Card(
                child: ListTile(
                  title: Text(station.name),
                  subtitle: Text(station.streamUrl),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isTesting ? Icons.stop : Icons.play_arrow,
                          color: isTesting
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => _testStation(station),
                        tooltip: isTesting ? 'Stop test' : 'Test station',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showStationDialog(context, provider, station),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            provider.removeStation(station.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showStationDialog(context, context.read<RadioStationProvider>()),
        icon: const Icon(Icons.add),
        label: const Text('Add Station'),
      ),
    );
  }

  Future<void> _showStationDialog(
    BuildContext context,
    RadioStationProvider provider, [
    RadioStation? station,
  ]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: station?.name ?? '');
    final urlController =
        TextEditingController(text: station?.streamUrl ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station == null ? 'Add Station' : 'Edit Station'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Stream URL'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (station == null) {
                await provider.addStation(
                  name: nameController.text,
                  url: urlController.text,
                );
              } else {
                await provider.editStation(
                  station.copyWith(
                    name: nameController.text,
                    streamUrl: urlController.text,
                  ),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

