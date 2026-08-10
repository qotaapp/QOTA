import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// §26 : cliquer sur l'image ouvre l'image en plein écran avec zoom.
class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullscreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
