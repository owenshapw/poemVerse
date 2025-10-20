// lib/utils/text_menu_utils.dart

import 'package:flutter/material.dart';

/// 中文文本选择菜单工具类
class TextMenuUtils {
  /// 构建中文文本选择菜单
  static Widget buildChineseContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: editableTextState.contextMenuButtonItems.map((item) {
        switch (item.label) {
          case 'Cut':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '剪切'
            );
          case 'Copy':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '复制'
            );
          case 'Paste':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '粘贴'
            );
          case 'Select all':
          case 'Select All':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '全选'
            );
          case 'Look Up':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '查询'
            );
          case 'Search Web':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '网页搜索'
            );
          case 'Share':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '分享'
            );
          case 'Define':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '定义'
            );
          case 'Translate':
            return ContextMenuButtonItem(
              onPressed: item.onPressed, 
              label: '翻译'
            );
          default:
            return item;
        }
      }).toList(),
    );
  }
}