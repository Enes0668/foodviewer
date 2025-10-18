import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  DateTime selectedDate = DateTime.now();

  // Data holders
  List<Map<String, dynamic>> kahvaltilar = [];
  List<Map<String, dynamic>> aksamYemekleri = [];

  bool _isLoading = false; // For async date navigation

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final String dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      // Fetch breakfast
      DatabaseEvent kahvaltiEvent = await _database
          .child('users/${user.uid}/kahvaltilar')
          .orderByChild('kahvalti_tarihi')
          .equalTo(dateKey)
          .once();

      final kahvaltiData = <Map<String, dynamic>>[];
      if (kahvaltiEvent.snapshot.exists) {
        final values = (kahvaltiEvent.snapshot.value as Map).values;
        for (var val in values) {
          kahvaltiData.add(Map<String, dynamic>.from(val));
        }
      }

      // Fetch dinner
      DatabaseEvent aksamEvent = await _database
          .child('users/${user.uid}/aksam_yemekleri')
          .orderByChild('aksam_tarihi')
          .equalTo(dateKey)
          .once();

      final aksamData = <Map<String, dynamic>>[];
      if (aksamEvent.snapshot.exists) {
        final values = (aksamEvent.snapshot.value as Map).values;
        for (var val in values) {
          aksamData.add(Map<String, dynamic>.from(val));
        }
      }

      setState(() {
        kahvaltilar = kahvaltiData;
        aksamYemekleri = aksamData;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _previousDate() async {
    if (_isLoading) return;

    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    await _fetchMeals();
  }

  Future<void> _nextDate() async {
    if (_isLoading) return;

    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    await _fetchMeals();
  }

  Widget _buildMealCard(String title, List<Map<String, dynamic>> meals, List<String> fields) {
    if (meals.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text("No $title for this date.",
              style: TextStyle(color: Colors.green.shade900)),
        ),
      );
    }

    return Column(
      children: meals.map((meal) {
        return Card(
          color: Colors.green.shade50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900)),
                const SizedBox(height: 8),
                ...fields.map((f) => Text("$f: ${meal[f] ?? '-'}",
                    style: TextStyle(color: Colors.green.shade800))).toList(),
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
            // Date selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: _isLoading ? null : _nextDate,
                    child: const Text("Sonraki Gün", textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMealCard(
                      "Kahvaltılar",
                      kahvaltilar,
                      ["ana_kahvalti", "diger1", "diger2", "diger3"],
                    ),
                    const SizedBox(height: 20),
                    _buildMealCard(
                      "Akşam Yemekleri",
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
