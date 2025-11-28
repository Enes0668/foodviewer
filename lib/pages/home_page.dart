import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/firebase_database_service.dart';
import '../services/notification_service.dart';

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
  bool _notificationsEnabled = false;

  List<Map<String, dynamic>> kahvaltilar = [];
  List<Map<String, dynamic>> aksamYemekleri = [];

  @override
  void initState() {
    super.initState();

    // 🔔 Bildirim servisini başlat
    NotificationService.initializeNotification().then((_) {
      if (_notificationsEnabled) {
        _scheduleDailyMeals();
      }
    });

    _loadNotificationSetting();
    _fetchMeals();
    
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool("notifications") ?? false;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications", value);
  }

  Future<void> _cancelAllNotifications() async {
    await NotificationService.cancelAll();
  }

  // ===============================================================
  // 🔔 GÜNLÜK OTOMATİK BİLDİRİMLER
  // ===============================================================

  Future<void> _scheduleDailyMeals() async {
  // İstanbul saat dilimi
  final istanbul = tz.getLocation('Europe/Istanbul');

  // Kahvaltı → 05:30
  final tz.TZDateTime breakfastTime = tz.TZDateTime(
      istanbul, tz.TZDateTime.now(istanbul).year, tz.TZDateTime.now(istanbul).month,
      tz.TZDateTime.now(istanbul).day, 5, 30);
  if (breakfastTime.isBefore(tz.TZDateTime.now(istanbul))) {
    breakfastTime.add(const Duration(days: 1));
  }

  await NotificationService.scheduleDaily(
    breakfastTime.hour,
    breakfastTime.minute,
    id: 100,
    title: "🍳 Kahvaltı Zamanı!",
    body: "Gün güzel bir kahvaltıyla başlar! Bugünün menüsüne göz atmayı unutma.",
  );

  // Akşam Yemeği → 19:42
  final tz.TZDateTime dinnerTime = tz.TZDateTime(
      istanbul, tz.TZDateTime.now(istanbul).year, tz.TZDateTime.now(istanbul).month,
      tz.TZDateTime.now(istanbul).day, 20, 03);
  if (dinnerTime.isBefore(tz.TZDateTime.now(istanbul))) {
    dinnerTime.add(const Duration(days: 1));
  }

  await NotificationService.scheduleDaily(
    dinnerTime.hour,
    dinnerTime.minute,
    id: 101,
    title: "🍽 Akşam Yemeği Zamanı!",
    body: "Akşam yemeği seni bekliyor! Bugünün menüsüne bir göz atmaya ne dersin?",
  );

  print("📅 Günlük kahvaltı bildirimi: $breakfastTime");
  print("📅 Günlük akşam yemeği bildirimi: $dinnerTime");
}



  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ===============================================================

  // 🟢 Test Notification Butonu
  Widget _buildNotificationTestButton() {
    return ElevatedButton(
      onPressed: () async {
        if (!await Permission.notification.isGranted) {
          final status = await Permission.notification.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Notification permission not granted")),
            );
            return;
          }
        }

        await NotificationService.showTestNotification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bildirim hemen gönderildi")),
        );
      },
      child: const Text("Test Notification"),
    );
  }

  // -------------------- Firebase Meal Fetch --------------------
  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      DatabaseReference usersRef = _database.child('users');
      DatabaseEvent usersEvent = await usersRef.once();

      List<Map<String, dynamic>> allKahvaltilar = [];
      List<Map<String, dynamic>> allAksamYemekleri = [];

      if (usersEvent.snapshot.exists) {
        final usersData =
            Map<String, dynamic>.from(usersEvent.snapshot.value as Map);

        usersData.forEach((uid, userData) {
          final userMap = Map<String, dynamic>.from(userData);

          if (userMap.containsKey('kahvaltilar')) {
            final kahvaltiMap =
                Map<String, dynamic>.from(userMap['kahvaltilar']);
            kahvaltiMap.values.forEach((meal) {
              final mealMap = Map<String, dynamic>.from(meal);
              if (mealMap['kahvalti_tarihi'] == dateKey) {
                allKahvaltilar.add(mealMap);
              }
            });
          }

          if (userMap.containsKey('aksam_yemekleri')) {
            final aksamMap =
                Map<String, dynamic>.from(userMap['aksam_yemekleri']);
            aksamMap.values.forEach((meal) {
              final mealMap = Map<String, dynamic>.from(meal);
              if (mealMap['aksam_tarihi'] == dateKey) {
                allAksamYemekleri.add(mealMap);
              }
            });
          }
        });
      }

      setState(() {
        kahvaltilar = allKahvaltilar;
        aksamYemekleri = allAksamYemekleri;
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

  Widget _buildMealCard(String title, IconData icon,
      List<Map<String, dynamic>> meals, List<String> fields) {
    if (meals.isEmpty) {
      String message = title == "Kahvaltılar"
          ? "Kahvaltı öğünü bulunamadı"
          : "Akşam Yemeği öğünü bulunamadı";

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade50]),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.green.shade800, size: 28),
              const SizedBox(width: 12),
              Text(
                message,
                style: TextStyle(color: Colors.green.shade900, fontSize: 16),
              ),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.green, thickness: 1, height: 16),
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        "$f: ${meal[f] ?? '-'}",
                        style: TextStyle(color: Colors.green.shade800, fontSize: 16),
                      ),
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
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Yemek Gösterici"),
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
            SwitchListTile(
              title: const Text("Yemek Bildirimleri"),
              secondary: const Icon(Icons.notifications),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveNotificationSetting(value);

                if (!value) {
                  await _cancelAllNotifications();
                } else {
                  await _scheduleDailyMeals();
                }
              },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  color: Colors.green.shade700,
                  onPressed: _isLoading ? null : _previousDate,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: Colors.green.shade700,
                  onPressed: _isLoading ? null : _nextDate,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildNotificationTestButton(),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMealCard(
                            "Kahvaltılar",
                            Icons.free_breakfast,
                            kahvaltilar,
                            ["ana_kahvalti", "diger1", "diger2", "diger3"],
                          ),
                          const SizedBox(height: 20),
                          _buildMealCard(
                            "Akşam Yemekleri",
                            Icons.dinner_dining,
                            aksamYemekleri,
                            ["yemek1", "yemek2", "pilav_makarna", "meze", "tatli"],
                          ),
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
