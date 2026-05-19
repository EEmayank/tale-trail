import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/utils/constants.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/domain/entities/kid_profile.dart';

// ---------------------------------------------------------------------------
// ManageProfilesScreen
// ---------------------------------------------------------------------------

class ManageProfilesScreen extends ConsumerWidget {
  const ManageProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Profiles',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: TaleColors.warmGrey900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: TaleColors.warmGrey200),
        ),
      ),
      body: uid == null
          ? const _EmptyState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colParents)
                  .doc(uid)
                  .collection(AppConstants.colKids)
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: TaleColors.terracotta,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(TaleDimensions.paddingLg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: TaleColors.error),
                          const SizedBox(height: TaleDimensions.paddingMd),
                          Text(
                            'Failed to load profiles.',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: TaleColors.error,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final profiles = docs
                    .map((doc) => KidProfile.fromFirestore(doc))
                    .toList();

                return _ProfileListView(
                  profiles: profiles,
                  parentUid: uid,
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile list view
// ---------------------------------------------------------------------------

class _ProfileListView extends StatelessWidget {
  const _ProfileListView({
    required this.profiles,
    required this.parentUid,
  });

  final List<KidProfile> profiles;
  final String parentUid;

  @override
  Widget build(BuildContext context) {
    final canAddMore = profiles.length < AppConstants.maxKidProfiles;

    if (profiles.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: TaleDimensions.paddingMd,
            ),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: TaleColors.warmGrey100,
              indent: TaleDimensions.paddingLg,
              endIndent: TaleDimensions.paddingLg,
            ),
            itemBuilder: (context, index) {
              return _ProfileTile(
                profile: profiles[index],
                parentUid: parentUid,
              );
            },
          ),
        ),

        // Add button at bottom
        Padding(
          padding: const EdgeInsets.all(TaleDimensions.paddingLg),
          child: TaleButton(
            label: 'Add New Profile',
            onPressed: canAddMore
                ? () => context.push('/profiles/add')
                : null,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile tile
// ---------------------------------------------------------------------------

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.parentUid,
  });

  final KidProfile profile;
  final String parentUid;

  // ---------------------------------------------------------------------------
  // Edit bottom sheet
  // ---------------------------------------------------------------------------

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TaleDimensions.radiusLg),
        ),
      ),
      builder: (_) => _EditProfileSheet(
        profile: profile,
        parentUid: parentUid,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete confirmation
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaleDimensions.radiusLg),
        ),
        title: Text(
          'Delete Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey900,
              ),
        ),
        content: Text(
          'Are you sure you want to delete ${profile.name}\'s profile? '
          'This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TaleColors.warmGrey700,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: TaleColors.warmGrey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: TaleColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.colParents)
            .doc(parentUid)
            .collection(AppConstants.colKids)
            .doc(profile.id)
            .delete();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete profile. Please try again.'),
              backgroundColor: TaleColors.error,
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final avatarIndex = AppConstants.avatarIds.indexOf(profile.avatarId);
    final safeIndex =
        avatarIndex.isNegative ? 0 : avatarIndex % AppConstants.avatarColors.length;
    final bgColor = Color(AppConstants.avatarColors[safeIndex]);
    final emoji = AppConstants.avatarEmojis[profile.avatarId] ?? '😊';
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TaleDimensions.paddingLg,
        vertical: TaleDimensions.paddingSm,
      ),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: bgColor,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
      title: Text(
        profile.name,
        style: textTheme.titleMedium?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: TaleColors.warmGrey900,
        ),
      ),
      subtitle: Text(
        'Age ${profile.age}',
        style: textTheme.bodySmall?.copyWith(
          color: TaleColors.warmGrey500,
          fontFamily: 'Inter',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: TaleColors.warmGrey600,
            tooltip: 'Edit',
            onPressed: () => _showEditSheet(context),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: TaleColors.error,
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile bottom sheet
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.profile,
    required this.parentUid,
  });

  final KidProfile profile;
  final String parentUid;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late int _selectedAge;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedAge = widget.profile.age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colParents)
          .doc(widget.parentUid)
          .collection(AppConstants.colKids)
          .doc(widget.profile.id)
          .update({
        'name': _nameController.text.trim(),
        'age': _selectedAge,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: TaleColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: TaleDimensions.paddingLg,
        right: TaleDimensions.paddingLg,
        top: TaleDimensions.paddingLg,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + TaleDimensions.paddingXl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TaleColors.warmGrey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingLg),

            Text(
              'Edit Profile',
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: TaleColors.warmGrey900,
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingLg),

            // Name field
            Text(
              'Name',
              style: textTheme.labelMedium?.copyWith(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey700,
              ),
            ),
            const SizedBox(height: TaleDimensions.paddingSm),
            TextFormField(
              controller: _nameController,
              maxLength: AppConstants.maxKidNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Child\'s name',
                filled: true,
                fillColor: TaleColors.warmGrey100,
                counterStyle:
                    const TextStyle(color: TaleColors.warmGrey400, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
                  borderSide: const BorderSide(
                      color: TaleColors.terracotta, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
                  borderSide:
                      const BorderSide(color: TaleColors.error, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingMd,
                  vertical: TaleDimensions.paddingMd,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),

            const SizedBox(height: TaleDimensions.paddingMd),

            // Age selector
            Text(
              'Age',
              style: textTheme.labelMedium?.copyWith(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey700,
              ),
            ),
            const SizedBox(height: TaleDimensions.paddingSm),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    AppConstants.maxKidAge - AppConstants.minKidAge + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: TaleDimensions.paddingSm),
                itemBuilder: (context, index) {
                  final age = AppConstants.minKidAge + index;
                  final isSelected = _selectedAge == age;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAge = age),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: TaleDimensions.paddingLg,
                        vertical: TaleDimensions.paddingMd,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TaleColors.terracotta
                            : TaleColors.warmGrey100,
                        borderRadius: BorderRadius.circular(
                            TaleDimensions.radiusFull),
                      ),
                      child: Text(
                        '$age',
                        style: textTheme.labelLarge?.copyWith(
                          fontFamily: 'Inter',
                          color: isSelected
                              ? Colors.white
                              : TaleColors.warmGrey700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingXl),

            // Save button
            TaleButton(
              label: 'Save Changes',
              onPressed: _isLoading ? null : _save,
              isLoading: _isLoading,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TaleDimensions.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👶', style: TextStyle(fontSize: 64)),
            const SizedBox(height: TaleDimensions.paddingLg),
            Text(
              'No profiles yet',
              style: textTheme.headlineSmall?.copyWith(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TaleDimensions.paddingMd),
            Text(
              'Add your child\'s profile to get started.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: TaleColors.warmGrey500,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: TaleDimensions.paddingXl),
            TaleButton(
              label: 'Add Profile',
              onPressed: () => context.push('/profiles/add'),
            ),
          ],
        ),
      ),
    );
  }
}
