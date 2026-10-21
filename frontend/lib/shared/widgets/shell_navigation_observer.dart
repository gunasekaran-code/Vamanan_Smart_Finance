import 'package:flutter/widgets.dart';

/// Watches one shell branch's navigator so the app header can swap the
/// drawer button for a back arrow while a page is pushed on top of a tab
/// (e.g. `Navigator.push(MaterialPageRoute(...))` from a list screen).
///
/// go_router's `canPop()` already sees those pages; what the header lacks is
/// a signal to rebuild when one is pushed or popped — that's [changes].
///
/// A NavigatorObserver can only be attached to one navigator, so every
/// `StatefulShellBranch` gets its own instance; they all share [changes].
class ShellNavigationObserver extends NavigatorObserver {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  // Deferred a frame: pushes can happen mid-build, and listeners call
  // setState.
  void _notify() => WidgetsBinding.instance
      .addPostFrameCallback((_) => changes.value++);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();
}
