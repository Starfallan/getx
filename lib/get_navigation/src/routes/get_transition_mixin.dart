import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/default_transitions.dart';

mixin GetPageRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(microseconds: 300);

  // The transitionDuration is used to create the AnimationController which is only
  // built once, so when page transition builder is updated and transitionDuration
  // has a new value, the AnimationController cannot be updated automatically. So we
  // manually update its duration here.
  @override
  TickerFuture didPush() {
    controller?.duration = transitionDuration;
    return super.didPush();
  }

  // The reverseTransitionDuration is used to create the AnimationController
  // which is only built once, so when page transition builder is updated and
  // reverseTransitionDuration has a new value, the AnimationController cannot
  // be updated automatically. So we manually update its reverseDuration here.
  @override
  bool didPop(T? result) {
    controller?.reverseDuration = reverseTransitionDuration;
    return super.didPop(result);
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _delegatedTransition;

  static Widget? _delegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    final delegatedTransitionBuilder = getDelegatedTransitionBuilder;
    return delegatedTransitionBuilder != null
        ? delegatedTransitionBuilder(
            context, animation, secondaryAnimation, allowSnapshotting, child)
        : null;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog,
    // or there is no matching transition to use.
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    final bool nextRouteIsNotFullscreen =
        (nextRoute is! PageRoute<T>) || !nextRoute.fullscreenDialog;

    // If the next route has a delegated transition, then this route is able to
    // use that delegated transition to smoothly sync with the next route's
    // transition.
    final bool nextRouteHasDelegatedTransition =
        nextRoute is ModalRoute<T> && nextRoute.delegatedTransition != null;

    // Otherwise if the next route has the same route transition mixin as this
    // one, then this route will already be synced with its transition.
    return nextRouteIsNotFullscreen &&
        ((nextRoute is MaterialRouteTransitionMixin) ||
            nextRouteHasDelegatedTransition);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    // Suppress previous route from transitioning if this is a fullscreenDialog route.
    return previousRoute is PageRoute && !fullscreenDialog;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = buildContent(context);
    return Semantics(
        scopesRoute: true, explicitChildNodes: true, child: result);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
        this, context, animation, secondaryAnimation, child);
  }

  static DelegatedTransitionBuilder? get getDelegatedTransitionBuilder {
    switch (Get.defaultTransition) {
      case Transition.native:
        if (Platform.isIOS || Platform.isMacOS) {
          return null;
          // return CupertinoPageTransition.delegatedTransition;
        }
        return const ZoomPageTransitionsBuilder().delegatedTransition;

      case Transition.zoom:
        return const ZoomPageTransitionsBuilder().delegatedTransition;

      default:
        return null;
    }
  }

  static Widget buildPageTransitions<T>(
    PageRoute<T> rawRoute,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (Get.defaultTransition) {
      case Transition.native:
        if (Platform.isIOS || Platform.isMacOS) {
          return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
            rawRoute,
            context,
            animation,
            secondaryAnimation,
            child,
          );
        }
        return const ZoomPageTransitionsBuilder().buildTransitions(
          rawRoute,
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.cupertino || Transition.cupertinoDialog:
        return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
          rawRoute,
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.leftToRight:
        return SlideLeftTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.downToUp:
        return SlideDownTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.upToDown:
        return SlideTopTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.noTransition:
        return child;

      case Transition.rightToLeft:
        return SlideRightTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.zoom:
        return const ZoomPageTransitionsBuilder().buildTransitions(
          rawRoute,
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.fadeIn:
        return FadeInTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.rightToLeftWithFade:
        return RightToLeftFadeTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.leftToRightWithFade:
        return LeftToRightFadeTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.size:
        return SizeTransitions.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.fade:
        return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
          rawRoute,
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.topLevel:
        return const ZoomPageTransitionsBuilder().buildTransitions(
          rawRoute,
          context,
          animation,
          secondaryAnimation,
          child,
        );

      case Transition.circularReveal:
        return CircularRevealTransition.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );
    }
  }
}
