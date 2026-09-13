import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDWvgjusFMMEN_kLquou9H75cFV6xvpN9g",
            authDomain: "dictafit-gym-y-dieta-por-voz.firebaseapp.com",
            projectId: "dictafit-gym-y-dieta-por-voz",
            storageBucket: "dictafit-gym-y-dieta-por-voz.firebasestorage.app",
            messagingSenderId: "1028761004087",
            appId: "1:1028761004087:web:3c2365ef0cfcb8855c77b2",
            measurementId: "G-4JQ815DPKP"));
  } else {
    await Firebase.initializeApp();
  }
}
