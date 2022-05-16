import 'package:hive/hive.dart';
part 'eventModel.g.dart';

@HiveType(typeId: 0)
class Event {
  @HiveField(0)
  String name;

  @HiveField(1)
  String event;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  String description;

  @HiveField(4)
  int id;

  @HiveField(5)
  String reminder;

  Event({
    required this.name,
    required this.event,
    required this.dateTime,
    required this.description,
    required this.id,
    required this.reminder,
  });
}
