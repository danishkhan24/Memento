import 'package:flutter/material.dart';
import 'package:memento/src/eventModel.dart';
import 'package:hive/hive.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class AddOrEditEventScreen extends StatefulWidget {
  final bool isEdit;
  int? position;
  Event? event;

  AddOrEditEventScreen(this.isEdit, [this.position, this.event]);

  @override
  State<AddOrEditEventScreen> createState() => _AddOrEditEventScreenState();
}

class _AddOrEditEventScreenState extends State<AddOrEditEventScreen> {
  TextEditingController controllerName = new TextEditingController();
  TextEditingController controllerEvent = new TextEditingController();
  TextEditingController controllerDescription = new TextEditingController();
  DateTime dateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      controllerName.text = widget.event!.name;
      controllerEvent.text = widget.event!.event;
      controllerDescription.text = widget.event!.description;
    }

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      )),
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
                      )),
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
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            "${dateTime.day} - ${dateTime.month} - ${dateTime.year}"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          DatePicker.showDatePicker(context,
                              showTitleActions: true,
                              minTime: DateTime.now(),
                              maxTime: DateTime(2099, 12, 30),
                              onConfirm: (date) {
                            setState(() {
                              dateTime = date;
                            });
                          });
                        },
                        child: Icon(Icons.date_range),
                      )
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
                      )),
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
                        Event event = Event(
                            name: name,
                            event: eventName,
                            dateTime: dateTime,
                            description: description);
                        var box = await Hive.openBox<Event>('event');

                        if (widget.isEdit) {
                          box.putAt(widget.position!, event);
                        } else {
                          box.add(event);
                          AwesomeNotifications().createNotification(
                            content: NotificationContent(
                                id: box.length,
                                channelKey: 'event_channel',
                                title: "${event.name}'s ${event.event}",
                                body: "${event.description}"),
                            schedule: NotificationCalendar.fromDate(
                              date: DateTime.now().add(Duration(seconds: 30)),
                              repeats: true,
                            ),
                          );
                        }
                        box.close();
                        Navigator.pop(context);
                        const snackBar = SnackBar(
                            content:
                            Text("Event added successfully!"));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      } else {
                        const snackBar = SnackBar(
                            content:
                                Text("Fields like name and event can not be empty."));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
