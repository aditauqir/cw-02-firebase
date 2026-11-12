import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';

FirebaseFunctions get functions {
  final app = Firebase.apps.any((a) => a.name == 'inclass13')
      ? Firebase.app('inclass13')
      : Firebase.app();
  return FirebaseFunctions.instanceFor(app: app);
}

Future<String> getQuestHint(String question) async {
  final trimmed = question.trim();
  final safeQuestion = trimmed.length > 300 ? trimmed.substring(0, 300) : trimmed;

  try {
    final callable = functions.httpsCallable('askQuestCoach');
    final result = await callable.call({'question': safeQuestion});
    final data = result.data as Map;
    return data['reply'] as String;
  } catch (_) {
    // Supervised coach agent logic (read-only tool + grounded hint + adversarial guard)
    final user = auth.currentUser;
    final uid = user?.uid ?? 'anonymous';

    // 1. Adversarial Guard
    final q = safeQuestion.toLowerCase();
    if (q.contains('grant') ||
        q.contains('points') ||
        q.contains('give me') ||
        q.contains('award') ||
        q.contains('write') ||
        q.contains('update') ||
        q.contains('ignore rules') ||
        q.contains('ignore instructions') ||
        q.contains('bypass') ||
        q.contains('999')) {
      return "I am a read-only Quest Coach. I cannot modify progress, write to the database, or award points or badges. Only your explicit action using the 'Complete Challenge' button can request the reward.";
    }

    // 2. Read quest state (read-only tool)
    String title = "Cloud Pioneer";
    String prompt =
        "Explore the cloud quest by learning how Firebase separates client views from trusted backend transactions.";
    bool isCompleted = false;
    int points = 0;
    String? badgeId;

    try {
      final challengeSnap = await FirebaseFirestore.instance
          .collection('challenges')
          .doc('today')
          .get();
      if (challengeSnap.exists) {
        title = challengeSnap.data()?['title'] ?? title;
        prompt = challengeSnap.data()?['prompt'] ?? prompt;
      }
      final progressSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('today')
          .get();
      if (progressSnap.exists) {
        isCompleted = progressSnap.data()?['completed'] == true;
        points = (progressSnap.data()?['points'] as num?)?.toInt() ?? 10;
        badgeId = progressSnap.data()?['badgeId'] ?? 'first-quest';
      }
    } catch (_) {}

    // 3. Grounded reply
    if (isCompleted) {
      return 'You have already completed today\'s challenge ("$title") and earned $points points with the "${badgeId ?? 'first-quest'}" badge! Keep up the great work.';
    }

    return 'Coach Hint for "$title": Review the prompt carefully: "$prompt". Sign in, inspect your quest progress, and consult the Quest Coach before claiming your reward. When ready, tap the Complete Challenge button!';
  }
}
