import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_task_manager/models/event.dart';
import 'package:simple_task_manager/screens/add_event.dart';
import 'package:simple_task_manager/services/db_service.dart';
import 'package:simple_task_manager/utils/database_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:workmanager/workmanager.dart'; 

void main() {
WidgetsFlutterBinding.ensureInitialized(); 
  Workmanager.initialize( 
      callbackDispatcher, 
  ); 
  Workmanager.registerPeriodicTask( 
    "1", 
    "simplePeriodicTask", 
    frequency: Duration(minutes: 60), 
  );
  runApp(MyApp());
}

void callbackDispatcher() { 
  Workmanager.executeTask((task, inputData) { 
    FlutterLocalNotificationsPlugin flip = new FlutterLocalNotificationsPlugin(); 
    var android = new AndroidInitializationSettings('@mipmap/launcher_icon'); 
    var iOS = new IOSInitializationSettings(); 
    var settings = new InitializationSettings(android, iOS); 
    flip.initialize(settings); 
    _showNotificationWithDefaultSound(flip); 
    return Future.value(true); 
  }); 
} 

Future _showNotificationWithDefaultSound(flip) async { 
  var androidPlatformChannelSpecifics = new AndroidNotificationDetails( 
      'What 2 Do', 
      'W2D', 
      'ToDo Application', 
      importance: Importance.Max, 
      priority: Priority.High 
  ); 
  var iOSPlatformChannelSpecifics = new IOSNotificationDetails(); 
  var platformChannelSpecifics = new NotificationDetails( 
      androidPlatformChannelSpecifics, 
      iOSPlatformChannelSpecifics 
  ); 
  await flip.show(0, 'What To Do?', 
    'Come have a look at your To-Do Tasks', 
    platformChannelSpecifics, payload: 'Default_Sound'
  ); 
} 

ThemeData _darkTheme = ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
);

ThemeData _lightTheme = ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
);

bool _light = false;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What 2 Do',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarController _calendarController;
  TextEditingController _eventController;
  Map<DateTime, List<dynamic>> _events;
  List<dynamic> _selectedEvents;
  SharedPreferences prefs;
  DbService dbService;
  DatabaseHelper databaseHelper;
  bool valueFromAddEvent = false;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _eventController = TextEditingController();
    _events = {};
    _selectedEvents = [];
    dbService = DbService();
    databaseHelper = DatabaseHelper();
  }

  Map<DateTime, List<dynamic>> _fromModelToEvent(List<EventModel> events) {
    Map<DateTime, List<dynamic>> data = {};
    events.forEach((event) {
      DateTime date = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day, 12);
      if (data[date] == null) data[date] = [];
      data[date].add(event);
    });
    return data;
  }

  Map<String, dynamic> encodeMap(Map<DateTime, dynamic> map) {
    Map<String, dynamic> newMap = {};
    map.forEach((key, value) {
      newMap[key.toString()] = map[key];
    });

    return newMap;
  }

Future<void> _showMyDialog() async {
return showDialog<void>(
  context: context,
  barrierDismissible: false, // user must tap button!
  builder: (BuildContext context) {
    return AlertDialog(
      title: Text('Developer'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Made with ❤️ by'),
            Text('Karthik Raja'),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Okie😊'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  },
);
}  

  Map<DateTime, dynamic> decodeMap(Map<String, dynamic> map) {
    Map<DateTime, dynamic> newMap = {};
    map.forEach((key, value) {
      newMap[DateTime.parse(key)] = map[key];
    });
    return newMap;
  }

  _awaitReturnValueFromAddEvent() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEvent(),
        ));

    setState(() {});
  }

  _awaitReturnValueFromAddEventForUpdate(EventModel event) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEvent(
            event: event,
          ),
        ));

    setState(() {
      valueFromAddEvent = result;
      if (valueFromAddEvent) {
        _reloadPage();
      }
    });
  }

  _reloadPage() async {
    print("reload");
    await new Future.delayed(const Duration(milliseconds: 0));
    Navigator.of(context, rootNavigator: false).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomePage(),
          transitionDuration: Duration(seconds: 0),
        ),
        (Route<dynamic> route) => false);
  }

BoxDecoration _lightMode = BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/dark.jpg'),
    fit: BoxFit.cover
  )
);

BoxDecoration _darkMode = BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/bg (2).jpg'),
    fit: BoxFit.cover
  )
);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _light? _darkTheme : _lightTheme,
      home: Scaffold(
        body: Container(
          decoration: _light ? _darkMode : _lightMode,
          child: FutureBuilder<List<EventModel>>(
            future: databaseHelper.getTaskList(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<EventModel> allEvents = snapshot.data;
                if (allEvents.isNotEmpty) {
                  _events = _fromModelToEvent(allEvents);
                }
              }
              return SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.bottomLeft,
                        height: 80,
                        child: Row(
                          children: <Widget> [IconButton(
                              iconSize: 40.0,
                              icon: Icon(Icons.info_outline), onPressed: _showMyDialog
                            ),
                            DayNightSwitcher(
                              isDarkModeEnabled: _light, 
                              onStateChanged: (isDarkModeEnabled){
                                setState(() {
                                  _light = isDarkModeEnabled;
                                });
                              }
                            )
                          ]
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Today's",
                              style: TextStyle(fontSize: 32),
                            ),
                            SizedBox(height: 10),
                            Text("Task Report",
                                style: TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TableCalendar(
                          events: _events,
                          initialCalendarFormat: CalendarFormat.month,
                          calendarStyle: CalendarStyle(
                            todayColor: Theme.of(context).primaryColor,
                            selectedColor: Theme.of(context).primaryColorDark,
                            todayStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                                color: Colors.white),
                            weekendStyle:
                                TextStyle(color: Colors.deepOrange),
                            outsideDaysVisible: false,
                          ),
                          headerStyle: HeaderStyle(
                              centerHeaderTitle: true,
                              formatButtonDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              formatButtonTextStyle:
                                  TextStyle(color: Colors.white),
                              formatButtonShowsNext: false),
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                  color: Colors.lightBlue,
                                  fontWeight: FontWeight.bold),
                              weekendStyle: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold)),
                          onDaySelected: (date, events) {
                            setState(() {
                              _selectedEvents = events;
                            });
                          },
                          builders: CalendarBuilders(
                              selectedDayBuilder: (context, date, events) =>
                                  Container(
                                      margin: EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle),
                                      child: Text(
                                        date.day.toString(),
                                        style: TextStyle(color: Colors.white),
                                      )),
                              todayDayBuilder: (context, date, enevts) =>
                                  Container(
                                      margin: EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Colors.teal.shade300,
                                          shape: BoxShape.circle),
                                      child: Text(
                                        date.day.toString(),
                                        style: TextStyle(color: Colors.white),
                                      ))),
                          calendarController: _calendarController,
                        ),
                      ),
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Daily Tasks',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )),
                      ..._selectedEvents.map((event) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                  child: Text(
                                event.time.format(context),
                                // event.time.toString(),
                                style: TextStyle(fontSize: 16),
                              )),
                              GestureDetector(
                                onTap: () {
                                  _awaitReturnValueFromAddEventForUpdate(event);
                                },
                                child: Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    padding: EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    width: 200,
                                    decoration: BoxDecoration(
                                        color: Colors.teal[300],
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 2),
                                              blurRadius: 2.0)
                                        ]),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          event.title,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          event.description,
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    )),
                              )
                            ],
                          )))
                    ],
                  ));
            }),
        ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _awaitReturnValueFromAddEvent();
          }),
      )
    );
  }
}