import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class RawHtmlImageWidget extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const RawHtmlImageWidget({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<RawHtmlImageWidget> createState() => _RawHtmlImageWidgetState();
}

class _RawHtmlImageWidgetState extends State<RawHtmlImageWidget> {
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType = 'js-img-${widget.url.hashCode}';

    // Register once per type (Flutter doesn't allow re-registering)
    platformViewRegistry.registerViewFactory(viewType, (int _) {
      final img = web.document.createElement('img') as web.HTMLImageElement;
      img.src = widget.url;

      img.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'cover';

      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
