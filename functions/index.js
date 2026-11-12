import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp, getApps } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { generateQuestHint } from "./questCoach.js";

if (!getApps().length) {
  initializeApp();
}
const db = getFirestore();

/**
 * Trusted callable Cloud Function: completeToday
 * Awards 10 points and "first-quest" badge exactly once using an idempotent transaction.
 */
export const completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }
  const uid = request.auth.uid;
  const progressRef = db.doc(`users/${uid}/progress/today`);

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);
    if (progress.exists) {
      return {
        completed: true,
        points: progress.data().points,
        badgeId: progress.data().badgeId,
        alreadyCompleted: true
      };
    }
    const reward = {
      completed: true,
      points: 10,
      badgeId: "first-quest",
      completedAt: FieldValue.serverTimestamp()
    };
    transaction.set(progressRef, reward);
    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false
    };
  });
});

/**
 * Supervised Quest Coach callable: askQuestCoach
 * Validates sign-in and question, calls the readMyQuestState tool,
 * and returns a grounded hint.
 */
export const askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before asking the Quest Coach.");
  }

  const rawQuestion = request.data?.question;
  if (!rawQuestion || typeof rawQuestion !== "string" || !rawQuestion.trim()) {
    throw new HttpsError("invalid-argument", "Question must be a non-empty string of up to 300 characters.");
  }

  const question = rawQuestion.trim();
  if (question.length > 300) {
    throw new HttpsError("invalid-argument", "Question cannot exceed 300 characters.");
  }

  // Derive UID strictly from authenticated session
  const uid = request.auth.uid;

  try {
    const reply = await generateQuestHint(uid, question);
    return { reply };
  } catch (error) {
    console.error("Quest Coach internal error:", error);
    throw new HttpsError("internal", "The coach encountered an error loading your quest state.");
  }
});
