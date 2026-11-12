import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/coach_service.dart';
import '../services/reward_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _questionController = TextEditingController();
  bool _isLoadingHint = false;
  bool _isCompleting = false;
  String? _coachReply;
  String? _statusMessage;
  bool _statusIsSuccess = true;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    setState(() {
      _isCompleting = true;
      _statusMessage = null;
    });

    try {
      final result = await completeChallenge();
      final alreadyCompleted = result['alreadyCompleted'] == true;
      final points = result['points'] ?? 10;
      final badgeId = result['badgeId'] ?? 'first-quest';

      if (!mounted) return;
      setState(() {
        _statusIsSuccess = true;
        if (alreadyCompleted) {
          _statusMessage =
              'Reward verified. You already completed this quest ($points points, badge: "$badgeId"). Score does not increase.';
        } else {
          _statusMessage =
              'Quest Complete! You earned $points points and the "$badgeId" badge!';
        }
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _statusIsSuccess = false;
        _statusMessage = 'Completion failed: ${error.message ?? error.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusIsSuccess = false;
        _statusMessage = 'Error connecting to reward function: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _handleGetHint() async {
    final query = _questionController.text.trim();
    if (query.isEmpty) {
      setState(() => _coachReply = 'Please enter a question or hint request first.');
      return;
    }

    setState(() {
      _isLoadingHint = true;
      _coachReply = null;
    });

    try {
      final reply = await getQuestHint(query);
      if (!mounted) return;
      setState(() => _coachReply = reply);
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Quest Coach request failed: ${error.code}');
      if (!mounted) return;
      setState(() => _coachReply = 'The coach is unavailable (${error.code}). Try again.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _coachReply = 'The coach is currently offline. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHint = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Quest',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () async => await logOut(),
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc('today')
            .snapshots(),
        builder: (context, progressSnapshot) {
          final progressData = progressSnapshot.data?.data();
          final isCompleted = progressData?['completed'] == true;
          final points = (progressData?['points'] as num?)?.toInt() ?? 0;
          final badgeId = progressData?['badgeId'] as String?;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('challenges')
                .doc('today')
                .snapshots(),
            builder: (context, challengeSnapshot) {
              final challengeData = challengeSnapshot.data?.data();
              final challengeTitle =
                  challengeData?['title'] as String? ?? 'Cloud Quest Discovery';
              final challengePrompt = challengeData?['prompt'] as String? ??
                  'Complete quest and claim reward.';

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  // Challenge Title (no box, no chip)
                  Text(
                    challengeTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Challenge Prompt (clean text, no inner gray box)
                  Text(
                    challengePrompt,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Completion button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _handleComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.grey.shade200 : Colors.black,
                        foregroundColor: isCompleted ? Colors.grey.shade700 : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Text(
                              isCompleted
                                  ? 'Challenge Completed'
                                  : 'Complete Challenge',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  // Status / Feedback message (no emojis)
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _statusIsSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ] else if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Quest Complete! You earned $points points and the "${badgeId ?? 'first-quest'}" badge!',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 28),

                  // Quest Coach Section (no box, no SUPERVISED AI chip)
                  Text(
                    'Quest Coach',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask for a grounded hint based on your current quest state:',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          maxLength: 300,
                          style: GoogleFonts.outfit(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask a question...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoadingHint ? null : _handleGetHint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: _isLoadingHint
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Get hint',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Coach hint response (clean text, no box)
                  if (_coachReply != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _coachReply!,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
