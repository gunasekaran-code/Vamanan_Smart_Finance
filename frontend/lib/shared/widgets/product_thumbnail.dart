import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Product photo loaded from the server, with a neutral placeholder while
/// loading and when the product has no image (or it fails to load).
class ProductThumbnail extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ProductThumbnail({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder({bool loading = false}) => ColoredBox(
        color: const Color(0xFFF1F5F9),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCBD5E1)),
                )
              : Icon(Icons.inventory_2_outlined,
                  color: const Color(0xFF94A3B8), size: (width < height ? width : height) * 0.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (!kIsWeb && width.isFinite) ? (width * dpr).round() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: src.isEmpty
            ? _placeholder()
            : Image.network(
                src,
                fit: fit,
                cacheWidth: cacheWidth,
                filterQuality: FilterQuality.medium,
                // Upload files are served without CORS headers, so on web load
                // them through an <img> element, which the browser doesn't block.
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(loading: true),
              ),
      ),
    );
  }
}
