import 'package:flutter/material.dart';

class GlassShadowWrapper extends StatelessWidget {
  const GlassShadowWrapper({
    super.key,
    required this.child,
    required this.radius,
    this.blur = 10,
    this.opacity = 0.08,
    this.color = Colors.black,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FrostBox extends StatelessWidget {
  const _FrostBox({
    required this.child,
    required this.borderRadius,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: const Color(0xFF161D29).withOpacity(0.78),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class TopGlassButton extends StatelessWidget {
  const TopGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      child: _FrostBox(
        width: 48,
        height: 48,
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class GlassActionChip extends StatelessWidget {
  const GlassActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      child: _FrostBox(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFB9C5FF),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 24,
      child: _FrostBox(
        width: double.infinity,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class SoftGlassButton extends StatelessWidget {
  const SoftGlassButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 20,
      child: _FrostBox(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF8EA3FF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.removeBottomPadding = false,
  });

  final String label;
  final String value;
  final bool removeBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: removeBottomPadding ? 0 : 14),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}