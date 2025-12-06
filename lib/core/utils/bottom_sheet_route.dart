import 'package:flutter/material.dart';

class SmoothBottomSheetRoute<T> extends ModalRoute<T> {
  final WidgetBuilder builder;
  final Color? _barrierColor;
  final bool _isDismissible;
  final bool _enableDrag;
  final Duration _transitionDuration;

  SmoothBottomSheetRoute({
    required this.builder,
    Color? barrierColor,
    bool isDismissible = true,
    bool enableDrag = true,
    Duration transitionDuration = const Duration(milliseconds: 300),
  })  : _barrierColor = barrierColor,
        _isDismissible = isDismissible,
        _enableDrag = enableDrag,
        _transitionDuration = transitionDuration;

  @override
  Color? get barrierColor => _barrierColor ?? Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get barrierDismissible => _isDismissible;

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

