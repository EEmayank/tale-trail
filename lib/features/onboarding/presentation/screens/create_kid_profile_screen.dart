import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/core/utils/constants.dart';

// ---------------------------------------------------------------------------
// AddKidProfileScreen
// ---------------------------------------------------------------------------

class AddKidProfileScreen extends ConsumerStatefulWidget {
  const AddKidProfileScreen({super.key});

  @override
  ConsumerState<AddKidProfileScreen> createState() =>
      _AddKidProfileScreenState();
}

class _AddKidProfileScreenState extends ConsumerState<AddKidProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedAvatarId = AppConstants.avatarIds.first;
  int _selectedAge = AppConstants.minKidAge;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile({required bool addAnother}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) context.go('/signup');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = const Uuid().v4();
      final now = Timestamp.now();
      final avatarIndex =
          AppConstants.avatarIds.indexOf(_selectedAvatarId);

      await FirebaseFirestore.instance
          .collection(AppConstants.colParents)
          .doc(uid)
          .collection(AppConstants.colKids)
          .doc(id)
          .set({
        'name': _nameController.text.trim(),
        'age': _selectedAge,
        'avatarId': _selectedAvatarId,
        'avatarIndex': avatarIndex,
        'avatarCustomization': <String, String>{},
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;

      if (addAnother) {
        // Reset form for next child
        setState(() {
          _isLoading = false;
          _nameController.clear();
          _selectedAvatarId = AppConstants.avatarIds.first;
          _selectedAge = AppConstants.minKidAge;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile added! Add another child or tap "Let\'s Go!"',
            ),
            backgroundColor: TaleColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        context.go('/onboarding/pin');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: TaleColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TaleDimensions.paddingLg,
                    TaleDimensions.paddingXl,
                    TaleDimensions.paddingLg,
                    TaleDimensions.paddingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Who\'s reading?',
                        style: textTheme.displaySmall?.copyWith(
                          color: TaleColors.warmGrey900,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: TaleDimensions.paddingXs),
                      Text(
                        'Set up your child\'s profile',
                        style: textTheme.bodyLarge?.copyWith(
                          color: TaleColors.warmGrey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Avatar picker
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TaleDimensions.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose an avatar',
                        style: textTheme.titleMedium?.copyWith(
                          color: TaleColors.warmGrey800,
                        ),
                      ),
                      const SizedBox(height: TaleDimensions.paddingMd),
                      _AvatarPicker(
                        selectedAvatarId: _selectedAvatarId,
                        onSelected: (id) =>
                            setState(() => _selectedAvatarId = id),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: TaleDimensions.paddingXl),
              ),

              // Name field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TaleDimensions.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Child\'s Name',
                        style: textTheme.titleMedium?.copyWith(
                          color: TaleColors.warmGrey800,
                        ),
                      ),
                      const SizedBox(height: TaleDimensions.paddingMd),
                      TextFormField(
                        controller: _nameController,
                        maxLength: AppConstants.maxKidNameLength,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'e.g. Aanya, Riya, Sam',
                          hintStyle: TextStyle(
                              color: TaleColors.warmGrey400),
                          filled: true,
                          fillColor: Colors.white,
                          counterStyle: TextStyle(
                              color: TaleColors.warmGrey500, fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: TaleColors.warmGrey200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: TaleColors.warmGrey200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: TaleColors.terracotta, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: TaleColors.error, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: TaleColors.error, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: TaleDimensions.paddingMd,
                            vertical: TaleDimensions.paddingMd,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: TaleDimensions.paddingLg),
              ),

              // Age selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TaleDimensions.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Age',
                        style: textTheme.titleMedium?.copyWith(
                          color: TaleColors.warmGrey800,
                        ),
                      ),
                      const SizedBox(height: TaleDimensions.paddingMd),
                      _AgeSelector(
                        selectedAge: _selectedAge,
                        onSelected: (age) =>
                            setState(() => _selectedAge = age),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: TaleDimensions.paddingXl),
              ),

              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TaleDimensions.paddingLg),
                  child: Column(
                    children: [
                      // Primary: Let's Go!
                      TaleButton(
                        label: 'Let\'s Go! 🚀',
                        onPressed:
                            _isLoading ? null : () => _saveProfile(addAnother: false),
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: TaleDimensions.paddingMd),

                      // Secondary: Add Another Child
                      TaleButton(
                        label: 'Add Another Child',
                        onPressed:
                            _isLoading ? null : () => _saveProfile(addAnother: true),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: TaleDimensions.paddingXl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AvatarPicker — inline grid of 12 avatars
// ---------------------------------------------------------------------------

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.selectedAvatarId,
    required this.onSelected,
  });

  final String selectedAvatarId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: AppConstants.avatarIds.length,
      itemBuilder: (context, index) {
        final avatarId = AppConstants.avatarIds[index];
        final emoji = AppConstants.avatarEmojis[avatarId] ?? '😊';
        final colorValue = AppConstants.avatarColors[index];
        final bgColor = Color(colorValue);
        final isSelected = selectedAvatarId == avatarId;

        return GestureDetector(
          onTap: () => onSelected(avatarId),
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: TaleColors.terracotta,
                        width: 4,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 4,
                      ),
              ),
              child: CircleAvatar(
                backgroundColor: bgColor,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AgeSelector — horizontal scrollable pill buttons
// ---------------------------------------------------------------------------

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({
    required this.selectedAge,
    required this.onSelected,
  });

  final int selectedAge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:
            AppConstants.maxKidAge - AppConstants.minKidAge + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(width: TaleDimensions.paddingMd),
        itemBuilder: (context, index) {
          final age = AppConstants.minKidAge + index;
          final isSelected = selectedAge == age;

          return GestureDetector(
            onTap: () => onSelected(age),
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
                borderRadius:
                    BorderRadius.circular(TaleDimensions.radiusFull),
              ),
              child: Text(
                '$age',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
    );
  }
}
