import 'package:hive/hive.dart';

part 'radio_station.g.dart';

@HiveType(typeId: 1)
class RadioStation extends HiveObject {
  RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String streamUrl;

  RadioStation copyWith({
    String? id,
    String? name,
    String? streamUrl,
  }) {
    return RadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
      };

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] as String,
      name: json['name'] as String,
      streamUrl: json['streamUrl'] as String,
    );
  }
}

