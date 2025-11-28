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
  final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

  try {
    DatabaseReference usersRef = _database.child('users');
    DatabaseEvent usersEvent = await usersRef.once();

    List<Map<String, dynamic>> allKahvaltilar = [];
    List<Map<String, dynamic>> allAksamYemekleri = [];

    if (usersEvent.snapshot.exists) {
      final usersData = Map<String, dynamic>.from(usersEvent.snapshot.value as Map);

      usersData.forEach((uid, userData) {
        final userMap = Map<String, dynamic>.from(userData);

        // Kahvaltıları filtrele ve ekle
        if (userMap.containsKey('kahvaltilar')) {
          final kahvaltiMap = Map<String, dynamic>.from(userMap['kahvaltilar']);
          kahvaltiMap.values.forEach((meal) {
            final mealMap = Map<String, dynamic>.from(meal);
            if (mealMap['kahvalti_tarihi'] == dateKey) {
              allKahvaltilar.add(mealMap);
            }
          });
        }

        // Akşam yemeklerini filtrele ve ekle
        if (userMap.containsKey('aksam_yemekleri')) {
          final aksamMap = Map<String, dynamic>.from(userMap['aksam_yemekleri']);
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

  Widget _buildMealCard(
    String title, IconData icon, List<Map<String, dynamic>> meals, List<String> fields) {
  
  // Eğer liste boşsa Türkçe mesaj göster
  if (meals.isEmpty) {
    String message = "";

    if (title == "Kahvaltılar") {
      message = "Kahvaltı öğünü bulunamadı";
    } else if (title == "Akşam Yemekleri") {
      message = "Akşam Yemeği öğünü bulunamadı";
    } else {
      message = "Öğün bulunamadı";
    }

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
            Text(
              message,
              style: TextStyle(color: Colors.green.shade900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Eğer öğün varsa kartları oluştur
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
    final user = _auth.currentUser;

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
  // Butonlar artık küçük olduğu için Row'un ana eksende ortalanmasını sağlayabiliriz.
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // 1. Önceki Gün Butonu (IconButton ile küçültüldü)
    IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      color: Colors.green.shade700, // Buton rengi
      onPressed: _isLoading ? null : _previousDate,
    ),

    // 2. Tarih Metni (Expanded içinde, kalan tüm alanı kullanıyor)
    Expanded(
      // IconButton'lar arasında daha iyi bir boşluk sağlamak için Center'ı kaldırdım.
      // Eğer çok yapışık durursa, Text'e yatay padding verebilirsiniz.
      child: Padding( 
        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Opsiyonel küçük bir boşluk
        child: Text(
          DateFormat('dd.MM.yyyy').format(selectedDate),
          textAlign: TextAlign.center, // Metni ortada tut
          maxLines: 1, // Alt alta gelmesini engelle
          overflow: TextOverflow.ellipsis, // Sadece aşırı kritik durumlarda "..." gösterir
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ),

    // 3. Sonraki Gün Butonu (IconButton ile küçültüldü)
    IconButton(
      icon: const Icon(Icons.arrow_forward_ios),
      color: Colors.green.shade700, // Buton rengi
      onPressed: _isLoading ? null : _nextDate,
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
