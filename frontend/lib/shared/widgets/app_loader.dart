import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:frontend/core/theme/app_theme.dart';

const String _kLogoAsset = 'assets/images/logo.png';

/// App-wide page loader.
///
/// Drop `const AppLoader()` wherever a page is loading. While any AppLoader
/// is mounted, [AppLoaderHost] (installed once in `MaterialApp.builder`)
/// shows a single full-screen overlay: the blurred page behind, and the
/// brand logo centred with an animated ring. The AppLoader itself takes no
/// space in the page layout.
///
/// For actions that aren't tied to a widget's lifecycle (e.g. a submit),
/// use [GlobalLoader.show]/[GlobalLoader.hide] or [GlobalLoader.run].
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
    GlobalLoader.show();
  }

  @override
  void dispose() {
    GlobalLoader.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Global show/hide counter behind the full-screen loader. Calls are
/// reference-counted, so nested loads keep the overlay up until all finish.
class GlobalLoader {
  GlobalLoader._();

  static final ValueNotifier<int> _count = ValueNotifier<int>(0);
  static int _pending = 0;

  static ValueListenable<int> get listenable => _count;

  static void show() => _apply(1);

  static void hide() => _apply(-1);

  /// Shows the loader while [task] runs.
  static Future<T> run<T>(Future<T> Function() task) async {
    show();
    try {
      return await task();
    } finally {
      hide();
    }
  }

  // Loaders mount/unmount mid-build, so the notifier is updated after the
  // frame rather than synchronously (which would rebuild the host while the
  // tree is locked).
  static void _apply(int delta) {
    _pending += delta;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _count.value = math.max(0, _pending);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }
}

/// Hosts the full-screen loader above the whole app. Wrap the router's child
/// with it in `MaterialApp.builder`.
class AppLoaderHost extends StatefulWidget {
  final Widget child;

  const AppLoaderHost({super.key, required this.child});

  @override
  State<AppLoaderHost> createState() => _AppLoaderHostState();
}

class _AppLoaderHostState extends State<AppLoaderHost> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(_kLogoAsset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ValueListenableBuilder<int>(
            valueListenable: GlobalLoader.listenable,
            builder: (context, count, _) {
              final visible = count > 0;
              return IgnorePointer(
                ignoring: !visible,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: visible
                      ? const _LoaderOverlay(key: ValueKey('app-loader'))
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoaderOverlay extends StatelessWidget {
  const _LoaderOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Sits above the Navigator, so it brings its own Material for text styles.
    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [
                Colors.white.withOpacity(0.72),
                AppColors.kPrimaryLight.withOpacity(0.55),
              ],
            ),
          ),
          alignment: Alignment.center,
          // Swallow taps so the page underneath can't be used mid-load.
          child: const AbsorbPointer(child: BrandLoadingIndicator()),
        ),
      ),
    );
  }
}

/// The animated logo itself (logo badge, rotating gold ring, pulsing glow
/// and "LOADING" caption). Sized for phones vs tablets; usable on its own
/// where an inline, non-overlay loader is wanted.
class BrandLoadingIndicator extends StatefulWidget {
  final String label;

  const BrandLoadingIndicator({super.key, this.label = 'LOADING'});

  @override
  State<BrandLoadingIndicator> createState() => _BrandLoadingIndicatorState();
}

class _BrandLoadingIndicatorState extends State<BrandLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final isTablet = shortest >= 600;
    final logoSize = isTablet ? 104.0 : 76.0;
    final ringSize = logoSize + (isTablet ? 34 : 26);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              // 0 → 1 → 0 once per cycle, eased.
              final pulse = Curves.easeInOut.transform(1 - (2 * t - 1).abs());
              return SizedBox(
                width: ringSize + 24,
                height: ringSize + 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft gold glow that breathes with the pulse.
                    Container(
                      width: ringSize + 12 * pulse,
                      height: ringSize + 12 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldColor.withOpacity(0.18 + 0.17 * pulse),
                            blurRadius: 26 + 14 * pulse,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Rotating gold → navy sweep ring.
                    Transform.rotate(
                      angle: t * 2 * math.pi,
                      child: CustomPaint(
                        size: Size.square(ringSize),
                        painter: _RingPainter(strokeWidth: isTablet ? 4 : 3.2),
                      ),
                    ),
                    Transform.scale(scale: 0.96 + 0.04 * pulse, child: child),
                  ],
                ),
              );
            },
            child: Container(
              width: logoSize,
              height: logoSize,
              padding: EdgeInsets.all(isTablet ? 10 : 7),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldColor.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kPrimary.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _kLogoAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 320,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 18 : 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final dots = (_controller.value * 4).floor() % 4;
              return Text(
                // Fixed-width dots so the caption doesn't jitter.
                '${widget.label}${'.' * dots}${' ' * (3 - dots)}',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 3,
                  color: AppColors.kPrimary,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double strokeWidth;

  _RingPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);

    // Faint full track.
    canvas.drawOval(
      inset,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.goldColor.withOpacity(0.12),
    );

    // Bright sweeping arc with a fading tail.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppColors.goldColor.withOpacity(0),
          AppColors.goldColor,
          AppColors.kPrimary,
        ],
        stops: const [0.0, 0.55, 0.75],
      ).createShader(rect);
    canvas.drawArc(inset, 0, math.pi * 1.5, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
