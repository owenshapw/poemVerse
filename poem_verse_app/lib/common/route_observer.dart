import 'package:flutter/widgets.dart';

/// 全局 RouteObserver，用来在页面被 pop 回来时通知订阅者刷新
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
