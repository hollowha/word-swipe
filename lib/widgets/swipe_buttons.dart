import 'package:flutter/material.dart';
import '../theme.dart';

class SwipeButtons extends StatelessWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const SwipeButtons({super.key, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          onTap: onLeft,
          icon: Icons.close_rounded,
          color: AppTheme.learning,
          size: 60,
        ),
        const SizedBox(width: 40),
        _CircleButton(
          onTap: onRight,
          icon: Icons.check_rounded,
          color: AppTheme.know,
          size: 68,
        ),
        const SizedBox(width: 40),
        // Placeholder to balance layout (future: shuffle, bookmark, etc.)
        const SizedBox(width: 60),
      ],
    );
  }
}

class _CircleButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;

  const _CircleButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        await _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: widget.size * 0.42),
        ),
      ),
    );
  }
}
