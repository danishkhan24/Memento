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

  Event({
    required this.name,
    required this.event,
    required this.dateTime,
    required this.description,
  });

/*  factory Event.fromJson(Map<String, dynamic> json){
    return Event(
        name: json['name'],
        event: json['event'],
        dateTime: json['dateTime'],
        description: json['description']
    );
  }*/

  static int daysBetween(Event event) {
    DateTime now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(event.dateTime.year, event.dateTime.month, event.dateTime.day);
    return (to.difference(from).inHours / 24).round();
  }
}

/*class Item {
  Event event;
  late int daysLeft;

  Item({required this.event, daysLeft}){
    daysLeft = Event.daysBetween(this.event);
  }

  factory Item.fromJson(Map<String, dynamic> parsedJson){
    return Item(
        event: Event.fromJson(parsedJson['event']),
        daysLeft: parsedJson['description']
    );
  }
}*/
