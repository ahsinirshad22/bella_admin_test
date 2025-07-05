import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/widgets/raw_html_image_widget.dart';

class CrossPlatformImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CrossPlatformImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return RawHtmlImageWidget(
        url: url,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }
}
