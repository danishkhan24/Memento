import 'dart:math';
import 'package:flutter/material.dart';
import 'package:memento/eventModel.dart';
import 'package:hive/hive.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AddOrEditEventScreen extends StatefulWidget {
  final bool isEdit;
  final int? position;
  final Event? event;

  AddOrEditEventScreen(this.isEdit, [this.position, this.event]);

  @override
  State<AddOrEditEventScreen> createState() => _AddOrEditEventScreenState();
}

class _AddOrEditEventScreenState extends State<AddOrEditEventScreen> {
  TextEditingController controllerName = new TextEditingController();
  TextEditingController controllerEvent = new TextEditingController();
  TextEditingController controllerDescription = new TextEditingController();
  DateTime dateTime = DateTime.now();
  String reminderValue = "Once";

  @override
  void initState() {
    if (widget.isEdit){
      controllerName.text = widget.event!.name;
      controllerEvent.text = widget.event!.event;
      controllerDescription.text = widget.event!.description;
      reminderValue = widget.event!.reminder;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Name: "),
                      Expanded(
                        child: TextField(
                          controller: controllerName,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Event: "),
                      Expanded(
                        child: TextField(
                          controller: controllerEvent,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Pick Date:"),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                            "${dateTime.day} - ${dateTime.month} - ${dateTime.year} - ${dateTime.hour}:${dateTime.minute} "),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          DatePicker.showDatePicker(context,
                              showTitleActions: true,
                              minTime: DateTime(1950, 1, 1),
                              maxTime: DateTime(2099, 12, 30),
                              onConfirm: (date) {
                            setState(() {
                              dateTime = date;
                            });
                          });
                        },
                        child: Icon(Icons.date_range),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            DatePicker.showTime12hPicker(context,
                                showTitleActions: true, onConfirm: (date) {
                              setState(() {
                                dateTime = DateTime(
                                    dateTime.year,
                                    dateTime.month,
                                    dateTime.day,
                                    date.hour,
                                    date.minute);
                              });
                            });
                          },
                          child: Icon(Icons.schedule),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Description: "),
                      Expanded(
                        child: TextField(
                          controller: controllerDescription,
                          maxLength: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Remind Me: "),
                      DropdownButton(
                        value: reminderValue,
                        items: <String>[
                          'Once',
                          'Hourly',
                          'Daily',
                          'Monthly',
                          'Annually',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            reminderValue = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: ElevatedButton(
                    child: Text("Save"),
                    onPressed: () async {
                      String name = controllerName.text;
                      String eventName = controllerEvent.text;
                      String description = controllerDescription.text;

                      if (name.isNotEmpty && eventName.isNotEmpty) {
                        if (description.isEmpty)
                          description = "No Description.";
                        var rng = new Random();
                        int eventId = rng.nextInt(900000) + 100000;
                        Event event = Event(
                          name: name,
                          event: eventName,
                          dateTime: dateTime,
                          description: description,
                          id: eventId,
                          reminder: reminderValue,
                        );
                        var box = await Hive.openBox<Event>('event');
                        print(box.path);

                        if (widget.isEdit) {
                          AwesomeNotifications().cancelSchedule(event.id);
                          box.putAt(widget.position!, event);
                        } else {
                          box.add(event);
                        }
                        await scheduleNotification(event, reminderValue);
                        box.close();
                        const snackBar = SnackBar(
                            content: Text("Event added successfully!"));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      } else {
                        const snackBar = SnackBar(
                            content: Text(
                                "Fields like name and event can not be empty."));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> scheduleNotification(Event event, String reminderValue) async {
    int? month;
    int? day;
    int? hour;
    int? minute;
    DateTime schedule = event.dateTime;

    if (reminderValue == "Once") {
      print("creating one time reminder");
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: event.id,
            channelKey: 'event_channel',
            title: "${event.name}'s ${event.event}",
            body: "${event.description}"),
        schedule: NotificationCalendar(
          year: schedule.year,
          month: schedule.month,
          day: schedule.day,
          hour: schedule.hour,
          minute: schedule.minute,
        ),
      );
      return;
    } else if (reminderValue == "Annually") {
      month = schedule.month;
      day = 1;
      hour = 0;
      minute = 0;
    } else if (reminderValue == "Monthly") {
      day = schedule.day;
      hour = 0;
      minute = 0;
    } else if (reminderValue == "Daily") {
      hour = schedule.hour;
      minute = 0;
    } else if (reminderValue == "Hourly") {
      minute = schedule.minute;
    } else
      return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: event.id,
          channelKey: 'event_channel',
          title: "${event.name}'s ${event.event}",
          body: "${event.description}"),
      schedule: NotificationCalendar(
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
      ),
    );
  }
}
