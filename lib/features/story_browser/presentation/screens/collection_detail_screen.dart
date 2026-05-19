import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/illustrated_empty_state.dart';
import 'package:kids_stories/features/story_browser/data/models/story_summary.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';
import 'package:kids_stories/features/story_browser/presentation/widgets/story_card.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _CollectionData {
  const _CollectionData({
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.storyIds,
  });

  final String title;
  final String description;
  final String coverUrl;
  final List<String> storyIds;

  factory _CollectionData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return _CollectionData(
      title: data['title'] as String? ?? 'Collection',
      description: data['description'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      storyIds: (data['storyIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers (file-scoped)
// ---------------------------------------------------------------------------

final _collectionProvider =
    FutureProvider.family<_CollectionData, String>((ref, collectionId) async {
  final doc = await FirebaseFirestore.instance
      .collection('collections')
      .doc(collectionId)
      .get();
  if (!doc.exists) throw Exception('Collection not found');
  return _CollectionData.fromFirestore(doc);
});

/// Loads each story by id in parallel.
final _collectionStoriesProvider =
    FutureProvider.family<List<StorySummary>, List<String>>((ref, ids) async {
  final repo = ref.read(storyRepositoryProvider);
  final results = await Future.wait(
    ids.map((id) => repo.getStoryById(id)),
  );
  return results.whereType<StorySummary>().toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Displays all stories that belong to a Firestore collection document.
class CollectionDetailScreen extends ConsumerStatefulWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionAsync =
        ref.watch(_collectionProvider(widget.collectionId));

    return collectionAsync.when(
      loading: () => const _CollectionShimmer(),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: IllustratedEmptyState(
          title: 'Collection not found',
          subtitle: 'This collection may have been removed.',
          action: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ),
      ),
      data: (collection) => _CollectionBody(
        collection: collection,
        collectionId: widget.collectionId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CollectionBody
// ---------------------------------------------------------------------------

class _CollectionBody extends ConsumerWidget {
  const _CollectionBody({
    required this.collection,
    required this.collectionId,
  });

  final _CollectionData collection;
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync =
        ref.watch(_collectionStoriesProvider(collection.storyIds));

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: CustomScrollView(
        slivers: [
          // -----------------------------------------------------------------
          // Hero app bar with cover image
          // -----------------------------------------------------------------
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: TaleColors.terracotta,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleBackButton(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Text(
                collection.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        const Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (collection.coverUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: collection.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: TaleColors.terracottaLight,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: TaleColors.terracottaLight,
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TaleColors.terracottaLight,
                            TaleColors.terracotta,
                          ],
                        ),
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                        stops: [0.0, 0.5],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // Collection description
          // -----------------------------------------------------------------
          if (collection.description.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TaleDimensions.paddingMd,
                  TaleDimensions.paddingMd,
                  TaleDimensions.paddingMd,
                  0,
                ),
                child: Text(
                  collection.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TaleColors.warmGrey600,
                        height: 1.5,
                      ),
                ),
              ),
            ),

          // Story count badge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TaleDimensions.paddingMd,
                TaleDimensions.paddingMd,
                TaleDimensions.paddingMd,
                TaleDimensions.paddingSm,
              ),
              child: Text(
                '${collection.storyIds.length} ${collection.storyIds.length == 1 ? 'story' : 'stories'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TaleColors.warmGrey500,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // Stories grid
          // -----------------------------------------------------------------
          storiesAsync.when(
            loading: () => _ShimmerGrid(),
            error: (_, __) => SliverToBoxAdapter(
              child: IllustratedEmptyState(
                title: 'Could not load stories',
                subtitle: 'Please try again later.',
              ),
            ),
            data: (stories) {
              if (stories.isEmpty) {
                return SliverToBoxAdapter(
                  child: IllustratedEmptyState(
                    title: 'No stories in this collection',
                    subtitle: 'Check back soon!',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TaleDimensions.paddingMd,
                  0,
                  TaleDimensions.paddingMd,
                  TaleDimensions.paddingXxl,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 150 / 220,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final story = stories[index];
                      return StoryCard(
                        story: story,
                        onTap: () =>
                            context.push('/stories/${story.id}'),
                      );
                    },
                    childCount: stories.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(100),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _CollectionShimmer extends StatelessWidget {
  const _CollectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: Shimmer.fromColors(
        baseColor: TaleColors.warmGrey200,
        highlightColor: TaleColors.warmGrey100,
        child: Column(
          children: [
            Container(height: 240, color: TaleColors.warmGrey200),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TaleDimensions.paddingMd),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 150 / 220,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(TaleDimensions.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

SliverToBoxAdapter _ShimmerGrid() {
  return SliverToBoxAdapter(
    child: Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: Padding(
        padding: const EdgeInsets.all(TaleDimensions.paddingMd),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 150 / 220,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
            ),
          ),
        ),
      ),
    ),
  );
}
