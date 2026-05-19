import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/utils/constants.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/domain/entities/kid_profile.dart';
import 'package:kids_stories/features/profile/presentation/providers/profile_provider.dart';

// ---------------------------------------------------------------------------
// KidProfileSelectorScreen
// ---------------------------------------------------------------------------

class KidProfileSelectorScreen extends ConsumerStatefulWidget {
  const KidProfileSelectorScreen({super.key});

  @override
  ConsumerState<KidProfileSelectorScreen> createState() =>
      _KidProfileSelectorScreenState();
}

class _KidProfileSelectorScreenState
    extends ConsumerState<KidProfileSelectorScreen> {
  String? _selectedProfileId;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _selectProfile(KidProfile profile) async {
    setState(() => _selectedProfileId = profile.id);

    // Brief visual feedback delay before navigating
    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    ref.read(activeKidProfileProvider.notifier).state = profile;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastActiveProfileId, profile.id);

    if (mounted) {
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: TaleDimensions.paddingXl),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingLg),
              child: Text(
                'Who\'s reading today? 📚',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                  color: TaleColors.warmGrey900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingMd),

            Text(
              'Tap your name to start',
              style: textTheme.bodyLarge?.copyWith(
                color: TaleColors.warmGrey500,
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingXl),

            // Profile grid
            Expanded(
              child: uid == null
                  ? const _EmptyState()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection(AppConstants.colParents)
                          .doc(uid)
                          .collection(AppConstants.colKids)
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _ShimmerGrid();
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Something went wrong. Please try again.',
                              style: textTheme.bodyMedium?.copyWith(
                                  color: TaleColors.error),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final profiles = docs
                            .map((doc) => KidProfile.fromFirestore(doc))
                            .toList();

                        if (profiles.isEmpty) {
                          return const _EmptyState();
                        }

                        return _ProfileGrid(
                          profiles: profiles,
                          selectedProfileId: _selectedProfileId,
                          onSelect: _selectProfile,
                        );
                      },
                    ),
            ),

            // Parent settings button
            Padding(
              padding: const EdgeInsets.only(
                bottom: TaleDimensions.paddingLg,
                top: TaleDimensions.paddingMd,
              ),
              child: TextButton.icon(
                onPressed: () => context
                    .push('/parent-gate?redirect=/parent/settings'),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Parent ⚙️'),
                style: TextButton.styleFrom(
                  foregroundColor: TaleColors.warmGrey500,
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile grid
// ---------------------------------------------------------------------------

class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({
    required this.profiles,
    required this.selectedProfileId,
    required this.onSelect,
  });

  final List<KidProfile> profiles;
  final String? selectedProfileId;
  final ValueChanged<KidProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final showAddButton = profiles.length < AppConstants.maxKidProfiles;
    final itemCount = profiles.length + (showAddButton ? 1 : 0);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: TaleDimensions.paddingLg,
        vertical: TaleDimensions.paddingSm,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: TaleDimensions.paddingLg,
        crossAxisSpacing: TaleDimensions.paddingLg,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == profiles.length && showAddButton) {
          return _AddProfileCard();
        }

        final profile = profiles[index];
        return _ProfileCard(
          profile: profile,
          isSelected: selectedProfileId == profile.id,
          onTap: () => onSelect(profile),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final KidProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarIndex = AppConstants.avatarIds.indexOf(profile.avatarId);
    final safeIndex =
        avatarIndex.isNegative ? 0 : avatarIndex % AppConstants.avatarColors.length;
    final bgColor = Color(AppConstants.avatarColors[safeIndex]);
    final emoji = AppConstants.avatarEmojis[profile.avatarId] ?? '😊';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TaleDimensions.radiusLg),
            border: isSelected
                ? Border.all(color: TaleColors.terracotta, width: 4)
                : Border.all(color: TaleColors.warmGrey200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? TaleColors.terracotta.withAlpha(40)
                    : Colors.black.withAlpha(12),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: bgColor,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: TaleDimensions.paddingMd),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: TaleDimensions.paddingSm),
                child: Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TaleColors.warmGrey900,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Age ${profile.age}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TaleColors.warmGrey500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add profile card
// ---------------------------------------------------------------------------

class _AddProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profiles/add'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TaleDimensions.radiusLg),
          border: Border.all(
            color: TaleColors.warmGrey300,
            width: 2,
            // Dashed border via BoxDecoration is not natively supported,
            // so we use a solid border with a lighter color to suggest 'add'.
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: TaleColors.warmGrey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 36,
                color: TaleColors.warmGrey500,
              ),
            ),
            const SizedBox(height: TaleDimensions.paddingMd),
            Text(
              'Add Child',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: TaleColors.warmGrey600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: TaleDimensions.paddingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 64)),
          const SizedBox(height: TaleDimensions.paddingLg),
          Text(
            'No profiles yet',
            style: textTheme.headlineSmall?.copyWith(
              color: TaleColors.warmGrey700,
            ),
          ),
          const SizedBox(height: TaleDimensions.paddingMd),
          Text(
            'Add a child profile to start their reading adventure.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: TaleColors.warmGrey500,
            ),
          ),
          const SizedBox(height: TaleDimensions.paddingXl),
          TaleButton(
            label: 'Add Profile',
            onPressed: () => context.push('/profiles/add'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder grid
// ---------------------------------------------------------------------------

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: TaleDimensions.paddingLg,
          vertical: TaleDimensions.paddingSm,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: TaleDimensions.paddingLg,
          crossAxisSpacing: TaleDimensions.paddingLg,
          childAspectRatio: 0.85,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(TaleDimensions.radiusLg),
            ),
          );
        },
      ),
    );
  }
}
