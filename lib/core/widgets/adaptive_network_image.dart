import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Affiche une image réseau en conservant son ratio naturel, borné
/// entre un minimum "portrait" et un maximum "paysage" — le même
/// principe que Facebook/Instagram pour l'affichage des publications
/// sur mobile : une photo verticale (ex: prise en mode portrait) n'est
/// plus violemment recadrée en bandeau large, et une photo très large
/// n'explose plus la hauteur de la carte.
///
/// Par défaut : entre 4:5 (0.8, portrait) et 1.91:1 (paysage) — les
/// bornes standard utilisées par les réseaux sociaux mobiles.
class AdaptiveNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double minAspectRatio;
  final double maxAspectRatio;
  final BorderRadius? borderRadius;

  const AdaptiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.minAspectRatio = 0.8,
    this.maxAspectRatio = 1.91,
    this.borderRadius,
  });

  @override
  State<AdaptiveNetworkImage> createState() => _AdaptiveNetworkImageState();
}

class _AdaptiveNetworkImageState extends State<AdaptiveNetworkImage> {
  double? _ratio;
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _resolveNaturalRatio();
  }

  @override
  void didUpdateWidget(covariant AdaptiveNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _ratio = null;
      _resolveNaturalRatio();
    }
  }

  void _resolveNaturalRatio() {
    final provider = CachedNetworkImageProvider(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (height <= 0) {
          return;
        }
        final natural = width / height;
        final clamped =
            natural.clamp(widget.minAspectRatio, widget.maxAspectRatio);
        if (mounted) {
          setState(() => _ratio = clamped);
        }
      },
      onError: (_, __) {
        if (mounted) {
          setState(() => _ratio = 1); // repli carré si l'image ne charge pas
        }
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surfaceChip),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceChip,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );

    final content = AspectRatio(
      // Le carré (1:1) le temps de connaître la vraie dimension évite
      // un flash disgracieux ; le ratio réel prend le relais dès que
      // l'image est résolue (généralement quasi instantané, en cache).
      aspectRatio: _ratio ?? 1,
      child: image,
    );

    if (widget.borderRadius == null) {
      return content;
    }
    return ClipRRect(borderRadius: widget.borderRadius!, child: content);
  }
}
