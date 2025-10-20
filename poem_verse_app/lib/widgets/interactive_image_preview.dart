// lib/widgets/interactive_image_preview.dart
// ignore_for_file: deprecated_member_use, sized_box_for_whitespace, avoid_print
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/widgets/network_image_with_dio.dart';

class InteractiveImagePreview extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final Function(double offsetX, double offsetY, double scale)? onTransformChanged;
  final bool isInteractive;
  final BoxFit fit;

  const InteractiveImagePreview({
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
  State<InteractiveImagePreview> createState() => _InteractiveImagePreviewState();
}

class _InteractiveImagePreviewState extends State<InteractiveImagePreview> with SingleTickerProviderStateMixin {
  static const double _minScale = 1.0; // scaling disabled (user only pans vertically)
  static const double _maxScale = 1.0;

  late final TransformationController _transformationController;
  bool _internalUpdate = false;

  // image natural size resolution
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  double _lastResolvedContainerWidth = -1.0;
  double _lastResolvedContainerHeight = -1.0;
  bool _initialized = false;

  // computed display height so image width fills container
  double? _displayImageHeight;

  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    // initial transform will be applied directly to the controller
    _transformationController = TransformationController();
    // start identity; will update after we resolve image size
    _transformationController.value = Matrix4.identity();
    _transformationController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    if (_internalUpdate) {
      return;
    }
    final m = _transformationController.value;
    double tx = m.storage[12];
    double ty = m.storage[13];

    // Force horizontal movement to zero
    if (tx.abs() > 1e-6) {
      _internalUpdate = true;
      final corrected = Matrix4.identity()..translate(0.0, ty, 0.0);
      _transformationController.value = corrected;
      _internalUpdate = false;
      tx = 0.0;
    }

    final scale = 1.0; // scaling disabled
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) {
        return;
      }
      widget.onTransformChanged?.call(tx, ty, scale);
    });
  }

  void _resolveImageIfNeeded(double containerWidth, double containerHeight) {
    if (_initialized &&
        _lastResolvedContainerWidth == containerWidth &&
        _lastResolvedContainerHeight == containerHeight) {
      return;
    }
    _lastResolvedContainerWidth = containerWidth;
    _lastResolvedContainerHeight = containerHeight;

    // clean up previous stream
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
      _imageStream = null;
      _imageStreamListener = null;
    }

    final provider = NetworkImage(widget.imageUrl);
    final config = ImageConfiguration(devicePixelRatio: MediaQuery.of(context).devicePixelRatio);
    _imageStream = provider.resolve(config);
    _imageStreamListener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      final iw = info.image.width.toDouble();
      final ih = info.image.height.toDouble();

      if (!mounted) {
        return;
      }

      // Compute scale so image fills container width AND image height >= container height
      // (prevents blank when user pans vertically). This is equivalent to BoxFit.cover
      double displayHeight;
      if (iw > 0 && ih > 0) {
        final widthScale = containerWidth / iw;
        final heightScale = containerHeight / ih;
        final usedScale = widthScale > heightScale ? widthScale : heightScale;
        displayHeight = ih * usedScale;
      } else {
        displayHeight = containerWidth;
      }

      // update UI and controller: no scaling, only vertical translate
      setState(() {
        _displayImageHeight = displayHeight;
      });

      _internalUpdate = true;
      _transformationController.value = Matrix4.identity()..translate(0.0, widget.initialOffsetY, 0.0);
      _initialized = true;
      _internalUpdate = false;

      // notify once after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTransformChanged?.call(0.0, widget.initialOffsetY, 1.0);
      });
    }, onError: (dynamic error, StackTrace? stackTrace) {
      // ignore resolution errors; leave identity transform
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  @override
  void didUpdateWidget(covariant InteractiveImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果图片 URL 或初始偏移/缩放发生变化，重置显示状态以反映最新数据
    final urlChanged = widget.imageUrl != oldWidget.imageUrl;
    final offsetXChanged = widget.initialOffsetX != oldWidget.initialOffsetX;
    final offsetYChanged = widget.initialOffsetY != oldWidget.initialOffsetY;
    final scaleChanged = widget.initialScale != oldWidget.initialScale;

    if (urlChanged || offsetXChanged || offsetYChanged || scaleChanged) {
      // 强制重新计算 / 解析图片尺寸
      _initialized = false;
      _displayImageHeight = null;
      _lastResolvedContainerWidth = -1.0;
      _lastResolvedContainerHeight = -1.0;

      // 立即应用新的初始偏移/缩放到 controller（避免用户看不到更新）
      _internalUpdate = true;
      _transformationController.value =
          Matrix4.identity()..translate(widget.initialOffsetX, widget.initialOffsetY, 0.0);
      _internalUpdate = false;

      // 可选：强制清理缓存以确保新图片/变换被渲染
      if (urlChanged && widget.imageUrl.isNotEmpty) {
        final provider = NetworkImage(widget.imageUrl);
        provider.evict();
        PaintingBinding.instance.imageCache.evict(provider);
      }

      // 触发一次新的解析与回调（在下一帧）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveImageIfNeeded(
          widget.width.isFinite ? widget.width : MediaQuery.of(context).size.width,
          widget.height.isFinite ? widget.height : 180.0,
        );
        widget.onTransformChanged?.call(widget.initialOffsetX, widget.initialOffsetY, widget.initialScale);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _transformationController.removeListener(_onControllerChanged);
    _transformationController.dispose();
    super.dispose();
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

      // trigger resolving image natural size when container width is known
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveImageIfNeeded(availableWidth, availableHeight);
      });

      // If we computed display height, render image with width=availableWidth and that height
      Widget image;
      if (_displayImageHeight != null) {
        image = SizedBox(
          width: availableWidth,
          height: _displayImageHeight,
          child: NetworkImageWithDio(
            imageUrl: widget.imageUrl,
            fit: widget.fit,
            width: availableWidth,
            height: _displayImageHeight,
          ),
        );
      } else {
        // fallback while resolving:
        // DO NOT force height = container height (that caused the blank area).
        // Instead provide only width so the image keeps its aspect ratio.
        image = SizedBox(
          width: availableWidth,
          // height: null -> allow natural height according to image aspect ratio
          child: NetworkImageWithDio(
            imageUrl: widget.imageUrl,
            fit: widget.fit,
            width: availableWidth,
            height: null,
          ),
        );
      }

      return SizedBox(
        width: availableWidth.isFinite ? availableWidth : null,
        height: availableHeight.isFinite ? availableHeight : null,
        child: ClipRect(
          child: InteractiveViewer(
            transformationController: _transformationController,
            clipBehavior: Clip.hardEdge,
            constrained: false,
            panEnabled: widget.isInteractive,
            scaleEnabled: false, // disable pinch zoom
            minScale: _minScale,
            maxScale: _maxScale,
            // allow only vertical panning by giving 0 horizontal margin
            boundaryMargin: const EdgeInsets.symmetric(vertical: 2000, horizontal: 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: image,
            ),
            onInteractionStart: (details) {},
            onInteractionUpdate: (details) {},
            onInteractionEnd: (details) {},
          ),
        ),
      );
    });
  }
}

/* TransformedImage left unchanged */
class TransformedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double offsetX;
  final double offsetY;
  final double scale;
  final BoxFit fit;

  const TransformedImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final safeScale = scale.isFinite ? scale : 1.0;
    final safeOffsetX = offsetX.isFinite ? offsetX : 0.0;
    final safeOffsetY = offsetY.isFinite ? offsetY : 0.0;

    return ClipRect(
      child: Transform(
        transform: Matrix4.diagonal3Values(safeScale, safeScale, 1.0)
          ..multiply(Matrix4.translationValues(safeOffsetX / (safeScale == 0 ? 1.0 : safeScale),
              safeOffsetY / (safeScale == 0 ? 1.0 : safeScale), 0.0)),
        child: SizedBox(
          width: width,
          height: height,
          child: NetworkImageWithDio(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
          ),
        ),
      ),
    );
  }
}