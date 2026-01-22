/// Bouton avec animation de cercle noir au survol
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AnimatedGradientButton extends StatefulWidget {
  const AnimatedGradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool enabled;

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) {
          setState(() => _isHovering = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        if (widget.enabled) {
          setState(() => _isHovering = false);
          _controller.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Stack(
            children: [
              // Fond jaune de base
              Container(
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(0),
                ),
              ),

              // Cercle noir qui s'agrandit au survol
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return ClipRect(
                    child: CustomPaint(
                      painter: CircleExpandPainter(
                        progress: _animation.value,
                        color: const Color(0xFF2D2D2D),
                      ),
                      child: Container(),
                    ),
                  );
                },
              ),

              // Texte du bouton
              Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Color.lerp(
                          const Color(0xFF2D2D2D),
                          Colors.white,
                          _animation.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter pour dessiner le cercle qui s'agrandit depuis le centre
class CircleExpandPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleExpandPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * progress * 1.5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CircleExpandPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
