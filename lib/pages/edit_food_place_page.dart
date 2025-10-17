import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditFoodPlacePage extends StatefulWidget {
  final String uid;
  const EditFoodPlacePage({super.key, required this.uid});

  @override
  State<EditFoodPlacePage> createState() => _EditFoodPlacePageState();
}

class _EditFoodPlacePageState extends State<EditFoodPlacePage> {
  final _database = FirebaseDatabase.instance.ref();

  Map<String, dynamic> kahvaltilar = {};
  Map<String, dynamic> aksamYemekleri = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final kahvaltiSnap =
        await _database.child("users/${widget.uid}/kahvaltilar").get();
    final aksamSnap =
        await _database.child("users/${widget.uid}/aksam_yemekleri").get();

    setState(() {
      kahvaltilar =
          kahvaltiSnap.value != null ? Map<String, dynamic>.from(kahvaltiSnap.value as Map) : {};
      aksamYemekleri =
          aksamSnap.value != null ? Map<String, dynamic>.from(aksamSnap.value as Map) : {};
      _loading = false;
    });
  }

  Future<void> _deleteItem(String category, String key) async {
    await _database.child("users/${widget.uid}/$category/$key").remove();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Yemek silindi")),
    );
    _loadFoods();
  }

  Future<void> _editItem(String category, String key, Map item) async {
    final controllerMap = {
      for (var entry in item.entries)
        entry.key: TextEditingController(text: entry.value.toString())
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Yemeği Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              children: controllerMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final Map<String, Object?> updatedData = controllerMap.map(
             (key, controller) => MapEntry(key, controller.text),
                );
                await _database
                    .child("users/${widget.uid}/$category/$key")
                    .update(updatedData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yemek güncellendi")),
                );
                _loadFoods();
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFoodList(String title, String category, Map<String, dynamic> data) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("$title bulunamadı."),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...data.entries.map((entry) {
              final item = Map<String, dynamic>.from(entry.value);
              final tarihKey = category == "kahvaltilar"
                  ? "kahvalti_tarihi"
                  : "aksam_tarihi";
              final tarih = item[tarihKey] ?? "Tarih Yok";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey[100],
                child: ListTile(
                  title: Text("Tarih: $tarih"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: item.entries
                        .where((e) => e.key != tarihKey)
                        .map((e) => Text("${e.key}: ${e.value}"))
                        .toList(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editItem(category, entry.key, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(category, entry.key),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Girilen Yemekleri Düzenle")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFoods,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFoodList("Kahvaltılar", "kahvaltilar", kahvaltilar),
                    _buildFoodList(
                        "Akşam Yemekleri", "aksam_yemekleri", aksamYemekleri),
                  ],
                ),
              ),
            ),
    );
  }
}
