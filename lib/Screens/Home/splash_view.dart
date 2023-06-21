import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase/supabase.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  var currentUser = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  void checkLogin() async {
    // ignore: unused_local_variable
    final sharedPreferences = await SharedPreferences.getInstance();
    final session = currentUser;

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.blue,
          animating: true,
        ),
      ),
    );
  }
}
