import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';

/// Full-width illustration panel displayed at the top of the story player.
///
/// Resolution priority:
///   1. [localPath] (offline) — `File`-based SVG or raster image.
///   2. [illustrationUrl] ending in `.svg` — [SvgPicture.network].
///   3. Anything else — [CachedNetworkImage].
///
/// While loading, a shimmer placeholder fills the panel. On error, a centred
/// placeholder icon is shown.
class IllustrationPanel extends StatelessWidget {
  const IllustrationPanel({
    super.key,
    required this.illustrationUrl,
    required this.height,
    this.localPath,
  });

  /// Remote URL for the illustration. May end with `.svg` or be a raster URL.
  final String illustrationUrl;

  /// Height of the panel in logical pixels (typically 60–70% of screen height).
  final double height;

  /// Absolute path to a locally cached copy, used when offline.
  /// Takes precedence over [illustrationUrl] when non-null.
  final String? localPath;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool get _isNetworkSvg =>
      illustrationUrl.toLowerCase().endsWith('.svg') ||
      illustrationUrl.toLowerCase().contains('.svg?');

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // ── 1. Local file (offline) ────────────────────────────────────────────
    if (localPath != null) {
      return _LocalImage(path: localPath!, isNetworkSvg: false);
    }

    // ── 2. Network SVG ────────────────────────────────────────────────────
    if (_isNetworkSvg) {
      return _NetworkSvgImage(url: illustrationUrl);
    }

    // ── 3. Raster network image ────────────────────────────────────────────
    return _RasterNetworkImage(url: illustrationUrl);
  }
}

// ---------------------------------------------------------------------------
// _LocalImage
// ---------------------------------------------------------------------------

class _LocalImage extends StatelessWidget {
  const _LocalImage({required this.path, required this.isNetworkSvg});

  final String path;
  final bool isNetworkSvg;

  @override
  Widget build(BuildContext context) {
    final isSvg =
        path.toLowerCase().endsWith('.svg') ||
        path.toLowerCase().contains('.svg?');

    if (isSvg) {
      return SvgPicture.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        placeholderBuilder: (_) => _ShimmerPlaceholder(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _ErrorPlaceholder(),
    );
  }
}

// ---------------------------------------------------------------------------
// _NetworkSvgImage
// ---------------------------------------------------------------------------

class _NetworkSvgImage extends StatelessWidget {
  const _NetworkSvgImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholderBuilder: (_) => _ShimmerPlaceholder(),
    );
  }
}

// ---------------------------------------------------------------------------
// _RasterNetworkImage
// ---------------------------------------------------------------------------

class _RasterNetworkImage extends StatelessWidget {
  const _RasterNetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, _) => _ShimmerPlaceholder(),
      errorWidget: (context, _, __) => _ErrorPlaceholder(),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: TaleColors.warmGrey200,
      highlightColor: TaleColors.warmGrey100,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: TaleColors.warmGrey200,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error placeholder
// ---------------------------------------------------------------------------

class _ErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TaleColors.warmGrey200,
      child: const Center(
        child: Icon(
          Icons.image_rounded,
          size: 64,
          color: TaleColors.warmGrey300,
        ),
      ),
    );
  }
}
