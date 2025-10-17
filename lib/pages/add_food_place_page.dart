import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'edit_food_place_page.dart';

class AddFoodPlacePage extends StatefulWidget {
  final String uid;
  const AddFoodPlacePage({super.key, required this.uid});

  @override
  State<AddFoodPlacePage> createState() => _AddFoodPlacePageState();
}

class _AddFoodPlacePageState extends State<AddFoodPlacePage> {
  final _database = FirebaseDatabase.instance.ref();

  // Controllers for breakfast
  final _anaKahvaltiController = TextEditingController();
  final _diger1Controller = TextEditingController();
  final _diger2Controller = TextEditingController();
  final _diger3Controller = TextEditingController();
  DateTime? _kahvaltiDate;

  // Controllers for dinner
  final _yemek1Controller = TextEditingController();
  final _yemek2Controller = TextEditingController();
  final _pilavController = TextEditingController();
  final _mezeController = TextEditingController();
  final _tatliController = TextEditingController();
  DateTime? _aksamDate;

  Future<void> _selectDate(BuildContext context, bool isBreakfast) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBreakfast) {
          _kahvaltiDate = picked;
        } else {
          _aksamDate = picked;
        }
      });
    }
  }

  Future<void> _saveKahvalti() async {
    if (_kahvaltiDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen kahvaltı tarihini seçin.")),
      );
      return;
    }

    await _database.child("users/${widget.uid}/kahvaltilar").push().set({
      "ana_kahvalti": _anaKahvaltiController.text,
      "diger1": _diger1Controller.text,
      "diger2": _diger2Controller.text,
      "diger3": _diger3Controller.text,
      "kahvalti_tarihi": DateFormat('yyyy-MM-dd').format(_kahvaltiDate!),
    });

    _anaKahvaltiController.clear();
    _diger1Controller.clear();
    _diger2Controller.clear();
    _diger3Controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kahvaltı başarıyla kaydedildi!")),
    );
  }

  Future<void> _saveAksam() async {
    if (_aksamDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen akşam yemeği tarihini seçin.")),
      );
      return;
    }

    await _database.child("users/${widget.uid}/aksam_yemekleri").push().set({
      "yemek1": _yemek1Controller.text,
      "yemek2": _yemek2Controller.text,
      "pilav_makarna": _pilavController.text, // ✅ fixed key
      "meze": _mezeController.text,
      "tatli": _tatliController.text,
      "aksam_tarihi": DateFormat('yyyy-MM-dd').format(_aksamDate!),
    });

    _yemek1Controller.clear();
    _yemek2Controller.clear();
    _pilavController.clear();
    _mezeController.clear();
    _tatliController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Akşam yemeği başarıyla kaydedildi!")),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...fields,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yemek Ekleme Sayfası"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Kahvaltı
            _buildSection("Kahvaltı", [
              TextField(controller: _anaKahvaltiController, decoration: const InputDecoration(labelText: "Ana Kahvaltı")),
              const SizedBox(height: 10),
              TextField(controller: _diger1Controller, decoration: const InputDecoration(labelText: "Diğer 1")),
              const SizedBox(height: 10),
              TextField(controller: _diger2Controller, decoration: const InputDecoration(labelText: "Diğer 2")),
              const SizedBox(height: 10),
              TextField(controller: _diger3Controller, decoration: const InputDecoration(labelText: "Diğer 3")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(_kahvaltiDate == null
                        ? "Kahvaltı Tarihi Seçilmedi"
                        : "Tarih: ${DateFormat('dd.MM.yyyy').format(_kahvaltiDate!)}"),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text("Tarih Seç"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveKahvalti,
                child: const Text("Kahvaltıyı Kaydet"),
              ),
            ]),

            // Akşam Yemeği
            _buildSection("Akşam Yemeği", [
              TextField(controller: _yemek1Controller, decoration: const InputDecoration(labelText: "1. Yemek")),
              const SizedBox(height: 10),
              TextField(controller: _yemek2Controller, decoration: const InputDecoration(labelText: "2. Yemek")),
              const SizedBox(height: 10),
              TextField(controller: _pilavController, decoration: const InputDecoration(labelText: "Pilav / Makarna")),
              const SizedBox(height: 10),
              TextField(controller: _mezeController, decoration: const InputDecoration(labelText: "Meze (örn: Haydari, Ezme, Ayran)")),
              const SizedBox(height: 10),
              TextField(controller: _tatliController, decoration: const InputDecoration(labelText: "Tatlı (İsteğe bağlı)")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(_aksamDate == null
                        ? "Akşam Tarihi Seçilmedi"
                        : "Tarih: ${DateFormat('dd.MM.yyyy').format(_aksamDate!)}"),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, false),
                    child: const Text("Tarih Seç"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveAksam,
                child: const Text("Akşam Yemeğini Kaydet"),
              ),
            ]),
            const SizedBox(height: 20),
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoodPlacePage(uid: widget.uid),
      ),
    );
  },
  icon: const Icon(Icons.edit),
  label: const Text("Girilen Yemekleri Düzenle"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
          ],
        ),
      ),
    );
  }
}
