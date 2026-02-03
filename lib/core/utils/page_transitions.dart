import 'package:flutter/material.dart';

/// Custom page route transitions
class PageRouteTransitions {
  /// Fade transition
  static Route<T> fadeTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide from right transition
  static Route<T> slideFromRight<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Slide from bottom transition
  static Route<T> slideFromBottom<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Scale transition
  static Route<T> scaleTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return ScaleTransition(scale: animation.drive(tween), child: child);
      },
    );
  }

  /// Fade and slide transition
  static Route<T> fadeAndSlide<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        var slideTween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Rotation transition
  static Route<T> rotationTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return RotationTransition(
          turns: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Shared axis transition (Material Design)
  static Route<T> sharedAxisTransition<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension for easy navigation with custom transitions
extension NavigationExtension on BuildContext {
  Future<T?> pushWithTransition<T>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeAndSlide,
  }) {
    Route<T> route;

    switch (type) {
      case PageTransitionType.fade:
        route = PageRouteTransitions.fadeTransition<T>(page);
        break;
      case PageTransitionType.slideFromRight:
        route = PageRouteTransitions.slideFromRight<T>(page);
        break;
      case PageTransitionType.slideFromBottom:
        route = PageRouteTransitions.slideFromBottom<T>(page);
        break;
      case PageTransitionType.scale:
        route = PageRouteTransitions.scaleTransition<T>(page);
        break;
      case PageTransitionType.fadeAndSlide:
        route = PageRouteTransitions.fadeAndSlide<T>(page);
        break;
      case PageTransitionType.rotation:
        route = PageRouteTransitions.rotationTransition<T>(page);
        break;
      case PageTransitionType.sharedAxis:
        route = PageRouteTransitions.sharedAxisTransition<T>(page);
        break;
    }

    return Navigator.of(this).push(route);
  }

  Future<T?> pushReplacementWithTransition<T, TO>(
    Widget page, {
    PageTransitionType type = PageTransitionType.fadeAndSlide,
    TO? result,
  }) {
    Route<T> route;

    switch (type) {
      case PageTransitionType.fade:
        route = PageRouteTransitions.fadeTransition<T>(page);
        break;
      case PageTransitionType.slideFromRight:
        route = PageRouteTransitions.slideFromRight<T>(page);
        break;
      case PageTransitionType.slideFromBottom:
        route = PageRouteTransitions.slideFromBottom<T>(page);
        break;
      case PageTransitionType.scale:
        route = PageRouteTransitions.scaleTransition<T>(page);
        break;
      case PageTransitionType.fadeAndSlide:
        route = PageRouteTransitions.fadeAndSlide<T>(page);
        break;
      case PageTransitionType.rotation:
        route = PageRouteTransitions.rotationTransition<T>(page);
        break;
      case PageTransitionType.sharedAxis:
        route = PageRouteTransitions.sharedAxisTransition<T>(page);
        break;
    }

    return Navigator.of(this).pushReplacement(route, result: result);
  }
}

/// Page transition types
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromBottom,
  scale,
  fadeAndSlide,
  rotation,
  sharedAxis,
}
