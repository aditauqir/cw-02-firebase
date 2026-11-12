import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, Object?>> loadToday() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Sign in before loading learner progress.');
  }
  final challenge = await FirebaseFirestore.instance
      .collection('challenges')
      .doc('today')
      .get();
  final progress = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc('today')
      .get();
  return {
    'challenge': challenge.data(),
    'progress': progress.data(),
  };
}
