import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _foodController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _saveFood() async {
    final user = _auth.currentUser;
    final foodName = _foodController.text.trim();

    if (user != null && foodName.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foods')
          .add({'name': foodName, 'timestamp': FieldValue.serverTimestamp()});

      _foodController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food added successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoodViewer Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Welcome, ${user?.email ?? ''}'),
            const SizedBox(height: 20),
            TextField(
              controller: _foodController,
              decoration: const InputDecoration(
                labelText: 'Enter food name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveFood,
              child: const Text('Save Food'),
            ),
            const SizedBox(height: 20),
            const Text('Your Favorite Foods:'),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user?.uid)
                    .collection('foods')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final foods = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index]['name'];
                      return ListTile(
                        title: Text(food),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await foods[index].reference.delete();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
