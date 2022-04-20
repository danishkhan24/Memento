import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:memento/src/add_or_edit_event_screen.dart';
import 'package:memento/src/eventModel.dart';
import 'package:hive/hive.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class MyHomePage extends StatefulWidget {
  final bool darkMode;

  MyHomePage({Key? key, required this.darkMode}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState(darkMode);
}

class _MyHomePageState extends State<MyHomePage> {
  List<Event> eventList = [];
  bool _darkMode;

  _MyHomePageState(this._darkMode);

  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    getEvents();
    super.initState();
  }

  void getEvents() async {
    final box = await Hive.openBox<Event>('event');
    setState(() {
      eventList = box.values.toList();
    });
    box.close();
  }

  void deleteEvent(int key) async {
    final box = await Hive.openBox<Event>('event');
    box.deleteAt(key);
    setState(() {
      eventList.removeAt(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Memento"),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.black.withOpacity(0),
                  elevation: 0,
                ),
                onPressed: () {},
                child: Icon(Icons.account_circle_outlined, size: 36,),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddOrEditEventScreen(false)))
                .then((value) {
              getEvents();
            });
            getEvents();
          },
          child: Icon(Icons.add),
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                  child: Container(
                child: Image.asset("assets/splash_image.png"),
              )),
              ListTile(
                title: Text("Dark Mode"),
                trailing: Switch(
                  value: _darkMode,
                  onChanged: (bool value) {
                    setState(() {
                      _darkMode = value;
                    });
                    value
                        ? AdaptiveTheme.of(context).setDark()
                        : AdaptiveTheme.of(context).setLight();
                  },
                ),
              ),
              ListTile(
                title: Text("Logout"),
                trailing: Icon(Icons.logout, size: 28),
              )
            ],
          ),
        ),
        body: Container(
            child: ListView.builder(
          itemCount: eventList.length,
          itemBuilder: _itemBuilder,
        )));
  }

  Widget _itemBuilder(BuildContext context, position) {
    Event event = eventList[position];
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddOrEditEventScreen(true, position, event)))
              .then((value) {
            setState(() {
              getEvents();
            });

            AwesomeNotifications().createNotification(
              content: NotificationContent(
                  id: position,
                  channelKey: 'event_channel',
                  title: "${event.name}'s ${event.event}",
                  body: "${event.description}"),
              schedule: NotificationCalendar.fromDate(
                date: DateTime.now().add(Duration(seconds: 30)),
                repeats: true,
              ),
            );
          });
        },
        child: Card(
          elevation: 16,
          child: Container(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(event.name),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.date_range, color: Colors.blue),
                          ),
                          Text("${event.dateTime.day} - ${event.dateTime.month}"
                              " - ${event.dateTime.year}"),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(event.event),
                    ),
                    Container(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: ElevatedButton(
                            onPressed: ()  {
                              deleteEvent(position);
                              // await AwesomeNotifications().cancel(position);
                              AwesomeNotifications().cancelSchedule(position);
                              AwesomeNotifications().cancel(position);
                              // AwesomeNotifications().dismissedSink.close();
                              const snackBar = SnackBar(
                                  content: Text("Event Deleted Successfully!"));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              setState(() {
                                getEvents();
                              });
                            },
                            child: Icon(
                              Icons.delete,
                            )),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: screenWidth * 0.8,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(event.description),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
