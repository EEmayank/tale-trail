import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/features/auth/domain/entities/kid_profile.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';

/// Reading Reports Screen — shows per-kid reading stats for parents.
class ReadingReportsScreen extends ConsumerWidget {
  const ReadingReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeKidProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Reading Reports',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E2720),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E2720)),
      ),
      body: activeProfile == null
          ? const Center(
              child: Text(
                'Select a kid profile to view reports',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 16),
              ),
            )
          : _ReportBody(profile: activeProfile),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.profile});

  final KidProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStats(profile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kid header
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: TaleColors.warmGold,
                    child: const Text('📖', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E2720),
                        ),
                      ),
                      Text(
                        'Age ${profile.age}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF8C7B64),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Stories Read',
                    value: '${stats['storiesRead'] ?? 0}',
                    emoji: '📚',
                    color: TaleColors.terracottaLight,
                  ),
                  _StatCard(
                    label: 'Endings Found',
                    value: '${stats['endingsFound'] ?? 0}',
                    emoji: '⭐',
                    color: TaleColors.warmGold,
                  ),
                  _StatCard(
                    label: 'Day Streak',
                    value: '${stats['currentStreak'] ?? 0}',
                    emoji: '🔥',
                    color: const Color(0xFFFFB347),
                  ),
                  _StatCard(
                    label: 'Minutes Read',
                    value: '${stats['totalMinutes'] ?? 0}',
                    emoji: '⏱️',
                    color: TaleColors.info,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2720),
                ),
              ),

              const SizedBox(height: 16),

              if ((stats['recentStories'] as List?)?.isEmpty ?? true)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: TaleColors.parchment,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'No reading activity yet.\nStart a story to see reports here! 📖',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Color(0xFF8C7B64),
                      ),
                    ),
                  ),
                )
              else
                ...((stats['recentStories'] as List).map(
                  (s) => _RecentStoryTile(story: s as Map<String, dynamic>),
                )),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchStats(KidProfile profile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return {};

      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(uid)
          .collection('kids')
          .doc(profile.id)
          .collection('gamification')
          .doc('stats')
          .get();

      if (!doc.exists) return {};
      return doc.data() ?? {};
    } catch (_) {
      return {};
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  final String label;
  final String value;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2720),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF8C7B64),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStoryTile extends StatelessWidget {
  const _RecentStoryTile({required this.story});

  final Map<String, dynamic> story;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaleColors.parchment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TaleColors.warmGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('📖', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${story['title'] ?? 'Unknown Story'}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${story['percentComplete'] ?? 0}% complete',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Color(0xFF8C7B64),
                  ),
                ),
              ],
            ),
          ),
          if (story['isComplete'] == true)
            const Icon(
              Icons.check_circle,
              color: TaleColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
}
