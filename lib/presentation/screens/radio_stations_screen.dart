import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/radio_station.dart';
import '../providers/radio_station_provider.dart';

class RadioStationsScreen extends StatelessWidget {
  const RadioStationsScreen({super.key});

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
              return Card(
                child: ListTile(
                  title: Text(station.name),
                  subtitle: Text(station.streamUrl),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

