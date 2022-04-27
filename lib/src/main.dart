import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:memento/src/homePage.dart';
import 'package:hive/hive.dart';
import 'eventModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  Directory directory = await getApplicationDocumentsDirectory();
  FirebaseApp firebaseApp = await Firebase.initializeApp();
  Hive.init(directory.path);
  Hive.registerAdapter(EventAdapter());
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
            channelGroupKey: 'event_channel_group',
            channelKey: 'event_channel',
            channelName: 'Event notifications',
            channelDescription: 'Notification channel for events',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white)
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupkey: 'event',
            channelGroupName: 'Event group')
      ],
      debug: true);
  runApp(MyApp(
    savedThemeMode: savedThemeMode,
  ));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({Key? key, this.savedThemeMode}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    bool _darkMode = savedThemeMode?.isDark ?? false;

    return AdaptiveTheme(
      light: ThemeClass.lightTheme,
      dark: ThemeClass.darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: theme,
        darkTheme: darkTheme,
        home: MyHomePage(darkMode: _darkMode),
      ),
    );
  }
}

class ThemeClass {
  static ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
      ));

  static ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
      ));
}
