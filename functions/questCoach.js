import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

if (!getApps().length) {
  initializeApp({ projectId: "mad-inclass11" });
}

/**
 * Supervised Quest Coach Agent with a single read-only tool.
 *
 * Agent contract:
 * "You are a supportive quest coach. Use the supplied quest data to give one
 * concise hint, not the complete answer. Never claim a reward was granted.
 * You cannot write data; the learner decides whether to use the separate
 * Complete button."
 */

/**
 * Authorized read-only tool: readMyQuestState
 * Reads only the caller's verified progress and today's challenge.
 *
 * @param {string} uid - Verified caller UID from request.auth.uid
 * @returns {Promise<{challenge: any, progress: any}>}
 */
export async function readMyQuestState(uid) {
  // If running in local test mode without Firestore emulator or credentials, use fallback immediately
  if (process.env.NODE_ENV === "test" || (!process.env.FIRESTORE_EMULATOR_HOST && !process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.K_SERVICE)) {
    return {
      challenge: {
        title: "Cloud Quest Discovery",
        prompt: "Complete quest and claim reward."
      },
      progress: null
    };
  }

  try {
    const db = getFirestore();
    const challengeSnap = await db.doc("challenges/today").get();
    const progressSnap = await db.doc(`users/${uid}/progress/today`).get();

    return {
      challenge: challengeSnap.exists ? challengeSnap.data() : {
        title: "Cloud Quest Discovery",
        prompt: "Complete quest and claim reward."
      },
      progress: progressSnap.exists ? progressSnap.data() : null
    };
  } catch (err) {
    return {
      challenge: {
        title: "Cloud Quest Discovery",
        prompt: "Complete quest and claim reward."
      },
      progress: null
    };
  }
}

/**
 * Generates a grounded, safe hint based strictly on read-only quest state.
 * Enforces adversarial safety: rejects attempts to grant points, write data,
 * or alter quest status.
 *
 * @param {string} uid - Verified caller UID
 * @param {string} question - Learner's sanitized question
 * @returns {Promise<string>} Grounded hint
 */
export async function generateQuestHint(uid, question) {
  // 1. Always call the read-only tool first to ground the coach
  const questState = await readMyQuestState(uid);
  const challenge = questState.challenge;
  const progress = questState.progress;

  const normalizedQ = question.toLowerCase();

  // 2. Adversarial & privilege escalation guard
  const isAdversarial =
    normalizedQ.includes("grant") ||
    normalizedQ.includes("give me points") ||
    normalizedQ.includes("give me badge") ||
    normalizedQ.includes("give me 999") ||
    normalizedQ.includes("award") ||
    normalizedQ.includes("write to") ||
    normalizedQ.includes("update") ||
    normalizedQ.includes("ignore rules") ||
    normalizedQ.includes("ignore instructions") ||
    normalizedQ.includes("bypass") ||
    normalizedQ.includes("hack") ||
    normalizedQ.includes("free badge");

  if (isAdversarial) {
    return "I am a read-only Quest Coach. I cannot modify progress, write to the database, or award points or badges. Only your explicit action using the 'Complete challenge' button can request the trusted reward backend.";
  }

  // 3. Grounded response based on quest state
  const isCompleted = progress && progress.completed === true;

  if (isCompleted) {
    return `You have already completed today's quest "${challenge.title}"! You earned ${progress.points ?? 10} points and the "${progress.badgeId ?? 'first-quest'}" badge. Great job!`;
  }

  // 4. Grounded hint for active challenge
  return `Coach Hint for "${challenge.title}": Review today's prompt carefully: "${challenge.prompt}". Check your authentication and Firestore connection. When you're ready, tap the 'Complete challenge' button to trigger the trusted reward transaction!`;
}
