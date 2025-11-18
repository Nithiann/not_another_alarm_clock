import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/radio_station.dart';

class RadioStationProvider extends ChangeNotifier {
  RadioStationProvider() {
    _box = Hive.box<RadioStation>(_boxName);
    _stations = _box.values.toList();
    _subscription = _box.watch().listen((_) {
      _stations = _box.values.toList();
      notifyListeners();
    });
  }

  static const String _boxName = 'radio_stations';
  final Uuid _uuid = const Uuid();
  late Box<RadioStation> _box;
  StreamSubscription<BoxEvent>? _subscription;
  List<RadioStation> _stations = [];

  List<RadioStation> get stations => List.unmodifiable(_stations);

  RadioStation? getById(String? id) {
    if (id == null) return null;
    return _box.get(id);
  }

  Future<void> addStation({
    required String name,
    required String url,
  }) async {
    final station = RadioStation(
      id: _uuid.v4(),
      name: name.trim(),
      streamUrl: url.trim(),
    );
    await _box.put(station.id, station);
    _stations = _box.values.toList();
    notifyListeners();
  }

  Future<void> removeStation(String id) async {
    await _box.delete(id);
    _stations = _box.values.toList();
    notifyListeners();
  }

  Future<void> editStation(RadioStation updated) async {
    await _box.put(updated.id, updated);
    _stations = _box.values.toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

