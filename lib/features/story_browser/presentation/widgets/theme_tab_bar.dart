import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/features/story_browser/presentation/providers/story_browser_provider.dart';

// ---------------------------------------------------------------------------
// Theme data model
// ---------------------------------------------------------------------------

class _ThemeItem {
  const _ThemeItem({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;
}

const _themes = [
  _ThemeItem(id: 'all', label: 'All', emoji: '✨'),
  _ThemeItem(id: 'forest', label: 'Forest', emoji: '🌲'),
  _ThemeItem(id: 'space', label: 'Space', emoji: '🚀'),
  _ThemeItem(id: 'ocean', label: 'Ocean', emoji: '🌊'),
  _ThemeItem(id: 'animals', label: 'Animals', emoji: '🐾'),
  _ThemeItem(id: 'folklore', label: 'Folklore', emoji: '📖'),
  _ThemeItem(id: 'adventure', label: 'Adventure', emoji: '⚔️'),
];

// ---------------------------------------------------------------------------
// ThemeTabBar widget
// ---------------------------------------------------------------------------

class ThemeTabBar extends ConsumerStatefulWidget {
  const ThemeTabBar({super.key});

  @override
  ConsumerState<ThemeTabBar> createState() => _ThemeTabBarState();
}

class _ThemeTabBarState extends ConsumerState<ThemeTabBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTheme(String themeId) {
    final selected = themeId == 'all' ? null : themeId;
    ref.read(selectedThemeProvider.notifier).state = selected;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = ref.watch(selectedThemeProvider);
    final effectiveId = selectedTheme ?? 'all';

    return SizedBox(
      height: 44,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: TaleDimensions.paddingMd,
        ),
        itemCount: _themes.length,
        itemBuilder: (context, index) {
          final item = _themes[index];
          final isSelected = item.id == effectiveId;
          return Padding(
            padding: EdgeInsets.only(right: index < _themes.length - 1 ? 8 : 0),
            child: _ThemeTab(
              item: item,
              isSelected: isSelected,
              onTap: () => _selectTheme(item.id),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single tab chip
// ---------------------------------------------------------------------------

class _ThemeTab extends StatefulWidget {
  const _ThemeTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _ThemeItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ThemeTab> createState() => _ThemeTabState();
}

class _ThemeTabState extends State<_ThemeTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? TaleColors.terracotta
        : TaleColors.warmGrey100;
    final fg = widget.isSelected ? Colors.white : TaleColors.warmGrey600;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 5),
            Text(
              widget.item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
