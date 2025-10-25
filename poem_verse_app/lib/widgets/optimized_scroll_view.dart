// lib/widgets/optimized_scroll_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 优化的滚动视图，解决FlutterSemanticsScrollView的focusItemsInRect警告
class OptimizedScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const OptimizedScrollView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 优化无障碍语义，避免focusItemsInRect缓存问题
      container: true,
      explicitChildNodes: true,
      child: SingleChildScrollView(
        controller: controller,
        padding: padding,
        scrollDirection: scrollDirection,
        physics: physics ?? const ClampingScrollPhysics(),
        child: Column(
          children: children.map((child) => 
            Semantics(
              // 为每个子组件提供明确的语义边界
              container: true,
              child: child,
            )
          ).toList(),
        ),
      ),
    );
  }
}

/// 优化的ListView，专门用于解决语义滚动问题
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const ClampingScrollPhysics(),
      // 显式设置语义子节点，优化无障碍导航
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return Semantics(
          // 为列表项提供索引信息，优化无障碍导航
          sortKey: OrdinalSortKey(index.toDouble()),
          child: children[index],
        );
      },
    );
  }
}