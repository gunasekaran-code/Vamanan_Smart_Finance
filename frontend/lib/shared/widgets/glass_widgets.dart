import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.kPrimaryDark, AppColors.kPrimary, Color(0xFF101A3D)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _glowBlob(220, AppColors.kWarning.withOpacity(0.22)),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _glowBlob(260, AppColors.kInfo.withOpacity(0.20)),
          ),
          Positioned(
            top: 220,
            left: -40,
            child: _glowBlob(140, Colors.white.withOpacity(0.06)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

/// Generic frosted-glass panel: blurred, translucent, subtle border + shadow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 18,
    this.opacity = 0.12,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: Colors.white.withOpacity(0.26), width: 1.1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 28, offset: const Offset(0, 14)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Labeled glass input field with icon + optional obscure/reveal toggle.
class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Colors.white.withOpacity(0.82),
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 14,
          opacity: 0.09,
          blur: 10,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            cursorColor: AppColors.kWarning,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.42), fontWeight: FontWeight.w500),
              icon: Icon(widget.icon, size: 19, color: Colors.white.withOpacity(0.72)),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gold gradient primary CTA used across all auth screens.
class GoldGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  const GoldGradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.loading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C46A6), AppColors.kPrimary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.kPrimary.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(icon, color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular pill "back" button, glassy, top-left of every auth screen.
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GlassBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 14,
      opacity: 0.10,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Brand mark: rounded gradient badge with a crown/premium glyph, plus the
/// "Vamanan Enterprises V" wordmark and a small kicker subtitle underneath.
class BrandHeader extends StatelessWidget {
  final String kicker;
  const BrandHeader({super.key, required this.kicker});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [AppColors.kPrimary, AppColors.kPrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.kWarning.withOpacity(0.7), width: 1.6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 10)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.workspace_premium_rounded, color: AppColors.kWarning, size: 38),
          ),
        ),
        const SizedBox(height: 18),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white, letterSpacing: 0.2),
            children: [
              TextSpan(text: 'VAMANAN '),
              TextSpan(text: 'ENTERPRISES V', style: TextStyle(color: AppColors.kWarning)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _kickerLine(),
            const SizedBox(width: 10),
            Text(
              kicker,
              style: TextStyle(fontSize: 11.5, letterSpacing: 2, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            _kickerLine(),
          ],
        ),
      ],
    );
  }

  Widget _kickerLine() => Container(width: 22, height: 1, color: AppColors.kWarning.withOpacity(0.6));
}