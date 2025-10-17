import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'add_food_place_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://foodviewer-e65fa-default-rtdb.firebaseio.com/",
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    try {
      // 🔐 Sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // ✅ Check if user exists in database
      final userRef = _database.ref('users/$uid');
      final event = await userRef.once();

      if (event.snapshot.exists) {
        // 🟢 Go to AddFoodPlacePage WITH UID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddFoodPlacePage(uid: uid),
          ),
        );
      } else {
        // If user data doesn’t exist, create minimal profile
        await userRef.set({"email": email});

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddFoodPlacePage(uid: uid),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Giriş başarısız: ${e.message}";
      if (e.code == 'user-not-found') message = "Bu e-posta ile kullanıcı bulunamadı.";
      if (e.code == 'wrong-password') message = "Yanlış şifre girdiniz.";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beklenmedik hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yetkili Girişi')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "FoodViewer Yetkili Girişi",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _login,
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
