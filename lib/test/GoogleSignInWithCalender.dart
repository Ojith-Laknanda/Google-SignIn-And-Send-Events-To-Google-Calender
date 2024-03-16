import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth show AuthClient;


final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    calendar.CalendarApi.calendarScope,
  ],
);

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  GoogleSignInAccount? _currentUser;
  List<calendar.Event>? _events = [];

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }
  Future<void> _listEvents() async {
    final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
    if (client != null) {
      final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
      final now = DateTime.now().toUtc();
      final events = await calendarApi.events.list('primary',
          timeMin: now, maxResults: 10, singleEvents: true,
          orderBy: 'startTime');
      setState(() {
        _events = events.items;
      });
      print('Events listed successfully.');
    } else {
      print('Authentication error');
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Future<void> _createEvent(String eventName, DateTime startTime, DateTime endTime) async {
    final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
    if (client != null) {
      final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
      final event = calendar.Event()
        ..summary = eventName
        ..start = calendar.EventDateTime(dateTime: startTime.toUtc())
        ..end = calendar.EventDateTime(dateTime: endTime.toUtc());

      try {
        await calendarApi.events.insert(event, 'primary');
        print('Event created successfully.');
      } catch (error) {
        print('Error creating event: $error');
      }
    } else {
      print('Authentication error');
    }
  }

  DateTime _selectedStartTime = DateTime.now();
  DateTime _selectedEndTime = DateTime.now().add(Duration(days: 1));
  TextEditingController _eventNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In + Google Calendar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentUser != null)
              Text('Welcome, ${_currentUser!.displayName ?? ''}'),
            ElevatedButton(
              onPressed: _currentUser != null ? _handleSignOut : _handleSignIn,
              child: _currentUser != null ? Text('SIGN OUT') : Text('SIGN IN'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 200,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.dateAndTime,
                            onDateTimeChanged: (DateTime dateTime) {
                              setState(() {
                                _selectedStartTime = dateTime;
                              });
                            },
                            initialDateTime: _selectedStartTime,
                            minimumDate: DateTime(2019, 3, 5),
                            maximumDate: DateTime(2200, 6, 7),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Event Start Time',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                Text(_selectedStartTime.toString()),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 200,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.dateAndTime,
                            onDateTimeChanged: (DateTime dateTime) {
                              setState(() {
                                _selectedEndTime = dateTime;
                              });
                            },
                            initialDateTime: _selectedEndTime,
                            minimumDate: DateTime(2019, 3, 5),
                            maximumDate: DateTime(2200, 6, 7),
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Event End Time',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                Text(_selectedEndTime.toString()),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _eventNameController,
                decoration: InputDecoration(hintText: 'Enter Event name'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _createEvent(_eventNameController.text, _selectedStartTime, _selectedEndTime);
              },
              child: Text('Insert Event'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _listEvents();
              },
              child: Text('List Event'),
            ),
            if (_events != null)
              Column(
                children: _events!.map((event) {
                  return ListTile(
                    title: Text(event.summary ?? 'Untitled Event'),
                    subtitle: Text(event.start?.dateTime?.toString() ?? ''),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
