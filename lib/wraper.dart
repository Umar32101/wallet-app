import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Replace with your actual HomeScreen and LoginScreen
import 'home.dart' show MyHomePage;
import 'login.dart' show Login;


class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _resetSessionTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const sessionDuration = 10 * 60 * 1000; // 10 minutes
    return currentTime - loginTimestamp < sessionDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: _isSessionValid(),
              builder: (context, sessionSnapshot) {
                if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (sessionSnapshot.hasData && sessionSnapshot.data == true) {
                  _resetSessionTimer();
                  return  MyHomePage(username: FirebaseAuth.instance.currentUser!.email!);
                } else {
                  FirebaseAuth.instance.signOut();
                  return const Login();
                }
              },
            );
          } else {
            return const Login(); // Not logged in
          }
        },
      ),
    );
  }
}
