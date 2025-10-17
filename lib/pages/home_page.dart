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

    if (foodName.isEmpty) return;

    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foods')
          .add({'name': foodName, 'timestamp': FieldValue.serverTimestamp()});

      _foodController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food added successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to save food.")),
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
          // Button to open the drawer
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      // Drawer opens from right side
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
                Navigator.pop(context); // close drawer
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to about page if exists
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Welcome, ${user?.email ?? 'Guest'}'),
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
              child: user != null
                  ? StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('foods')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final foods = snapshot.data!.docs;

                        if (foods.isEmpty) {
                          return const Center(
                            child: Text('No foods added yet.'),
                          );
                        }

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
                    )
                  : const Center(
                      child: Text('Log in to see your favorite foods.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
