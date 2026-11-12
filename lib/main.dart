import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';

// Switch to true when running local Firebase Emulator Suite
const bool useEmulators = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  try {
    if (!Firebase.apps.any((app) => app.name == 'inclass13')) {
      await Firebase.initializeApp(
        name: 'inclass13',
        options: DefaultFirebaseOptions.inclass13,
      );
    }
  } catch (e) {
    debugPrint('inclass13 init notice: $e');
  }

  if (kDebugMode) {
    // 10.0.2.2 is the Android emulator alias to localhost
    const host = '10.0.2.2';
    try {
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    } catch (_) {}
  }

  // Seed challenges/today if not already present
  _ensureChallengeSeed();

  runApp(const CloudQuestApp());
}

void _ensureChallengeSeed() async {
  try {
    final challengeRef =
        FirebaseFirestore.instance.collection('challenges').doc('today');
    final doc = await challengeRef.get();
    if (!doc.exists) {
      await challengeRef.set({
        'title': 'Cloud Quest Discovery',
        'prompt': 'Complete quest and claim reward.',
      });
    }
  } catch (_) {
    // If rules prevent unauthenticated client write, backend handles seeding
  }
}
