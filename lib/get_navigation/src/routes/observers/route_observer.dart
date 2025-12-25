import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../../get_core/get_core.dart';
import '../../../../instance_manager.dart';
import '../../../get_navigation.dart';
import '../../router_report.dart';

/// Extracts the name of a route based on it's instance type
/// or null if not possible.
String? _extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }

  if (route is GetPageRoute) {
    return route.routeName;
  }

  if (route is DialogRoute) {
    return 'DIALOG ${route.hashCode}';
  }

  return null;
}

class GetObserver extends NavigatorObserver {
  final Function(Routing?)? routing;

  final Routing? _routeSend;

  GetObserver([this.routing, this._routeSend]);

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRoute = _RouteData.ofRoute(route);
    final newRoute = _RouteData.ofRoute(previousRoute);

    if (kDebugMode && currentRoute.isGetPageRoute) {
      Get.log("CLOSE TO ROUTE ${currentRoute.name}");
    }
    if (previousRoute != null) {
      RouterReportManager.reportCurrentRoute(previousRoute);
    }

    // Here we use a 'inverse didPush set', meaning that we use
    // previous route instead of 'route' because this is
    // a 'inverse push'
    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (previousRoute is PageRoute) {
        value.current = _extractRouteName(previousRoute) ?? '';
        value.previous = newRoute.name ?? '';
      } else if (value.previous.isNotEmpty) {
        value.current = value.previous;
      }

      value.args = previousRoute?.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
    });

    // print('currentRoute.isDialog ${currentRoute.isDialog}');

    routing?.call(_routeSend);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = _RouteData.ofRoute(route);

    if (kDebugMode && newRoute.isGetPageRoute) {
      Get.log("GOING TO ROUTE ${newRoute.name}");
    }

    RouterReportManager.reportCurrentRoute(route);
    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (route is PageRoute) {
        value.current = newRoute.name ?? '';
      }
      final previousRouteName = _extractRouteName(previousRoute);
      if (previousRouteName != null) {
        value.previous = previousRouteName;
      }

      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
    });

    if (routing != null) {
      routing!(_routeSend);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = _extractRouteName(route);

    if(kDebugMode) Get.log("REMOVING ROUTE $routeName");

    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = routeName ?? '';
      value.previous = routeName ?? '';
    });

    if (route is GetPageRoute) {
      RouterReportManager.reportRouteWillDispose(route);
    }
    routing?.call(_routeSend);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = _extractRouteName(newRoute);
    final oldName = _extractRouteName(oldRoute);

    if(kDebugMode) {
      Get.log("REPLACE ROUTE $oldName");
      Get.log("NEW ROUTE $newName");
    }

    if (newRoute != null) {
      RouterReportManager.reportCurrentRoute(newRoute);
    }

    _routeSend?.update((value) {
      // Only PageRoute is allowed to change current value
      if (newRoute is PageRoute) {
        value.current = newName ?? '';
      }

      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = '$oldName';
    });
    if (oldRoute is GetPageRoute) {
      RouterReportManager.reportRouteWillDispose(oldRoute);
    }

    routing?.call(_routeSend);
  }
}

class Routing {
  String current;
  String previous;
  dynamic args;
  String removed;
  Route<dynamic>? route;
  bool? isBack;
  bool? isDialog;

  Routing({
    this.current = '',
    this.previous = '',
    this.args,
    this.removed = '',
    this.route,
    this.isBack,
  });

  void update(void Function(Routing value) fn) {
    fn(this);
  }
}

/// This is basically a util for rules about 'what a route is'
class _RouteData {
  final bool isGetPageRoute;
  final String? name;

  _RouteData({
    required this.name,
    required this.isGetPageRoute,
  });

  factory _RouteData.ofRoute(Route? route) {
    return _RouteData(
      name: _extractRouteName(route),
      isGetPageRoute: route is GetPageRoute,
    );
  }
}
