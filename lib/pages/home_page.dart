import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../services/firebase_database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabaseService.ref;

  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Map<String, dynamic>> kahvaltilar = [];
  List<Map<String, dynamic>> aksamYemekleri = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchMeals();
    _scheduleDaily8AMNotification(); // ✅ Schedule once per day
  }

  /// Initialize notifications and timezone
  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// ✅ Schedule notification at 8:00 AM every day
  Future<void> _scheduleDaily8AMNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_meal_channel',
      'Daily Meal Notifications',
      channelDescription: 'Daily reminder to check today’s meals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 8, 0); // 8:00 AM

    // If 8:00 AM already passed, schedule for tomorrow
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '🍽 Bugünün yemeklerine göz at',
      'Tıklayarak bugünün menüsünü görüntüle!',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      DatabaseReference kahvaltiRef = _database.child('kahvaltilar');
      DatabaseReference aksamRef = _database.child('aksam_yemekleri');

      if (user != null) {
        kahvaltiRef = _database.child('users/${user.uid}/kahvaltilar');
        aksamRef = _database.child('users/${user.uid}/aksam_yemekleri');
      }

      DatabaseEvent kahvaltiEvent =
          await kahvaltiRef.orderByChild('kahvalti_tarihi').equalTo(dateKey).once();
      DatabaseEvent aksamEvent =
          await aksamRef.orderByChild('aksam_tarihi').equalTo(dateKey).once();

      List<Map<String, dynamic>> kahvaltiData = [];
      if (kahvaltiEvent.snapshot.exists) {
        for (var val in (kahvaltiEvent.snapshot.value as Map).values) {
          kahvaltiData.add(Map<String, dynamic>.from(val));
        }
      }

      List<Map<String, dynamic>> aksamData = [];
      if (aksamEvent.snapshot.exists) {
        for (var val in (aksamEvent.snapshot.value as Map).values) {
          aksamData.add(Map<String, dynamic>.from(val));
        }
      }

      setState(() {
        kahvaltilar = kahvaltiData;
        aksamYemekleri = aksamData;
      });
    } catch (e) {
      debugPrint("Error fetching meals: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _previousDate() async {
    if (_isLoading) return;
    setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
    await _fetchMeals();
  }

  Future<void> _nextDate() async {
    if (_isLoading) return;
    setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
    await _fetchMeals();
  }

  Widget _buildMealCard(
      String title, IconData icon, List<Map<String, dynamic>> meals, List<String> fields) {
    if (meals.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade100, Colors.green.shade50]),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.green.shade800, size: 28),
              const SizedBox(width: 12),
              Text("No $title for this date",
                  style: TextStyle(color: Colors.green.shade900, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: meals.map((meal) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.green.shade800, size: 28),
                    const SizedBox(width: 8),
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900)),
                  ],
                ),
                const Divider(color: Colors.green, thickness: 1, height: 16),
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text("$f: ${meal[f] ?? '-'}",
                          style: TextStyle(color: Colors.green.shade800, fontSize: 16)),
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("FoodViewer"),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Yetkili Girişi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _isLoading ? null : _previousDate,
                    child: const Text("Önceki Gün", textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 16),
                Text(DateFormat('dd.MM.yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _isLoading ? null : _nextDate,
                    child: const Text("Sonraki Gün", textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMealCard("Kahvaltılar", Icons.free_breakfast, kahvaltilar,
                              ["ana_kahvalti", "diger1", "diger2", "diger3"]),
                          const SizedBox(height: 20),
                          _buildMealCard("Akşam Yemekleri", Icons.dinner_dining,
                              aksamYemekleri,
                              ["yemek1", "yemek2", "pilav_makarna", "meze", "tatli"]),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
