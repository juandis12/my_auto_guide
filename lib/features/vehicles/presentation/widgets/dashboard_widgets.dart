import 'package:flutter/material.dart';
import '../../../../core/theme/brand_theme.dart';

class IndicatorTile extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final bool isSimit;
  final VoidCallback? onTap;

  const IndicatorTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.isSimit = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        width: 100,
        decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2))),
        child: Column(children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(
              height: 50,
              width: 50,
              child: Stack(fit: StackFit.expand, children: [
                CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor:
                        isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(color)),
                Center(
                    child: isSimit
                        ? Icon(Icons.gavel_rounded, color: color, size: 20)
                        : Text('${(value * 100).round()}%',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black)))
              ]))
        ]),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final BrandTheme? brandTheme;
  final bool isSpecial;

  const GradientButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.brandTheme,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = brandTheme ?? BrandTheme.defaultTheme;
    return ScaleButton(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSpecial 
                  ? LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : theme.gradient,
                boxShadow: [
                  if (isSpecial)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                ]),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 22)),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16)
            ])));
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const ScaleButton({super.key, required this.child, this.onTap, this.onLongPress});
  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: widget.child));
  }
}

class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const StaggeredFadeIn({super.key, required this.child, required this.delay});
  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _show = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        opacity: _show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            transform: Matrix4.translationValues(0, _show ? 0 : 30, 0),
            child: widget.child));
  }
}
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text.toUpperCase(),
        style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black45));
  }
}

class DocTileInteractive extends StatelessWidget {
  final String title;
  final String? path;
  final IconData icon;
  final VoidCallback onUpload;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final bool isUploading;

  const DocTileInteractive({
    super.key,
    required this.title,
    required this.path,
    required this.icon,
    required this.onUpload,
    this.onView,
    this.onDelete,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDoc = path != null;

    return ScaleButton(
      onTap: hasDoc ? onView : onUpload,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasDoc
                ? Colors.green.withOpacity(0.3)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasDoc
                        ? Colors.green.withOpacity(0.1)
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDoc ? Icons.check_circle_rounded : icon,
                    color: hasDoc
                        ? Colors.green
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 28,
                  ),
                ),
                if (isUploading)
                  const SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasDoc ? 'VER DOCUMENTO' : 'SUBIR ARCHIVO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: hasDoc ? Colors.green : Colors.blue,
              ),
            ),
            if (hasDoc && onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
