import 'package:flutter/material.dart';

/// Fixed interactive image preview that does NOT use `placeholder` / `errorWidget`
/// named parameters. Uses NetworkImageWithDio for image rendering.
class InteractiveImagePreviewFixed extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final ValueChanged<TransformData>? onTransformChanged;
  final bool isInteractive;
  final BoxFit fit;

  const InteractiveImagePreviewFixed({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.initialOffsetX = 0.0,
    this.initialOffsetY = 0.0,
    this.initialScale = 1.0,
    this.onTransformChanged,
    this.isInteractive = true,
    this.fit = BoxFit.cover,
  });

  @override
  State<InteractiveImagePreviewFixed> createState() => _InteractiveImagePreviewFixedState();
}

class TransformData {
  final double offsetX;
  final double offsetY;
  final double scale;
  TransformData(this.offsetX, this.offsetY, this.scale);
}

class _InteractiveImagePreviewFixedState extends State<InteractiveImagePreviewFixed> {
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  static const double _maxOffsetAbs = 20000.0;

  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  late double _startScale;
  late Offset _startOffset;
  Offset? _startFocalLocal;

  double _safeDouble(double v, double fallback) => v.isFinite ? v : fallback;
  double _safeScale(double v) => _safeDouble(v, 1.0).clamp(_minScale, _maxScale);
  Offset _safeOffset(Offset o) {
    final dx = _safeDouble(o.dx, 0.0).clamp(-_maxOffsetAbs, _maxOffsetAbs);
    final dy = _safeDouble(o.dy, 0.0).clamp(-_maxOffsetAbs, _maxOffsetAbs);
    return Offset(dx, dy);
  }

  @override
  void initState() {
    super.initState();
    _currentScale = _safeScale(widget.initialScale);
    _currentOffset = _safeOffset(Offset(widget.initialOffsetX, widget.initialOffsetY));
  }

  @override
  void didUpdateWidget(covariant InteractiveImagePreviewFixed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialScale != oldWidget.initialScale ||
        widget.initialOffsetX != oldWidget.initialOffsetX ||
        widget.initialOffsetY != oldWidget.initialOffsetY) {
      setState(() {
        _currentScale = _safeScale(widget.initialScale);
        _currentOffset = _safeOffset(Offset(widget.initialOffsetX, widget.initialOffsetY));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTransformChanged?.call(TransformData(_currentOffset.dx, _currentOffset.dy, _currentScale));
      });
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _safeScale(_currentScale);
    _startOffset = _safeOffset(_currentOffset);
    final box = context.findRenderObject() as RenderBox?;
    _startFocalLocal = box?.globalToLocal(details.focalPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isInteractive) return;

    final box = context.findRenderObject() as RenderBox?;
    final focalLocal = box?.globalToLocal(details.focalPoint);

    final rawScale = _safeDouble(details.scale, 1.0);
    final newScale = (_startScale * rawScale).clamp(_minScale, _maxScale);

    Offset newOffset = _startOffset;
    final startScaleSafe = (_startScale.isFinite && _startScale != 0.0) ? _startScale : 1.0;
    if (focalLocal != null && _startFocalLocal != null) {
      final ratio = newScale / startScaleSafe;
      final dx = focalLocal.dx - (focalLocal.dx - _startOffset.dx) * ratio;
      final dy = focalLocal.dy - (focalLocal.dy - _startOffset.dy) * ratio;
      newOffset = Offset(dx, dy);
    } else {
      final delta = details.focalPointDelta;
      final dx = _safeDouble(_startOffset.dx + delta.dx, _startOffset.dx);
      final dy = _safeDouble(_startOffset.dy + delta.dy, _startOffset.dy);
      newOffset = Offset(dx, dy);
    }

    if (!newScale.isFinite || !newOffset.dx.isFinite || !newOffset.dy.isFinite) {
      return;
    }

    newOffset = _safeOffset(newOffset);

    final scaleChanged = (_currentScale - newScale).abs() > 1e-6;
    final offsetChanged = (_currentOffset - newOffset).distance > 0.5;
    if (!scaleChanged && !offsetChanged) return;

    setState(() {
      _currentScale = newScale;
      _currentOffset = newOffset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTransformChanged?.call(TransformData(_currentOffset.dx, _currentOffset.dy, _currentScale));
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {}

  Widget _imageWidget(double w, double h) {
    return NetworkImageWithDio(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: w.isFinite ? w : null,
      height: h.isFinite ? h : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = widget.width.isFinite
          ? widget.width
          : (constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width);
      final availableHeight = widget.height.isFinite
          ? widget.height
          : (constraints.maxHeight.isFinite ? constraints.maxHeight : 180.0);

      final safeScale = _safeScale(_currentScale);
      final safeOffset = _safeOffset(_currentOffset);

      final transformSafe = safeScale.isFinite &&
          safeOffset.dx.isFinite &&
          safeOffset.dy.isFinite &&
          availableWidth.isFinite &&
          availableHeight.isFinite;

      Widget image = SizedBox(
        width: availableWidth.isFinite ? availableWidth : 0.0,
        height: availableHeight.isFinite ? availableHeight : 0.0,
        child: _imageWidget(availableWidth, availableHeight),
      );

      final displayed = transformSafe
          ? Transform(
              transform: Matrix4.translationValues(safeOffset.dx, safeOffset.dy, 0.0)
                  ..multiply(Matrix4.diagonal3Values(safeScale, safeScale, 1.0)),
              alignment: Alignment.topLeft,
              child: image,
            )
          : image;

      return SizedBox(
        width: availableWidth.isFinite ? availableWidth : null,
        height: availableHeight.isFinite ? availableHeight : null,
        child: ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: Stack(fit: StackFit.expand, children: [displayed]),
          ),
        ),
      );
    });
  }
}

/// Simple NetworkImage wrapper without debug logs or external colored frames.
class NetworkImageWithDio extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const NetworkImageWithDio({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 28),
      );
    }
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {

        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 28),
        );
      },
    );
  }
}