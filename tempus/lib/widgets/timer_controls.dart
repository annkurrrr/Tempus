import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Start / Pause / Resume / Save control buttons for the timer.
class TimerControls extends StatelessWidget {
  final bool isRunning;
  final bool hasStarted;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSave;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.hasStarted,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasStarted) {
      return _PrimaryButton(
        label: 'START',
        icon: Icons.play_arrow_rounded,
        onPressed: onStart,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isRunning
              ? _SecondaryButton(
                  key: const ValueKey('pause'),
                  label: 'PAUSE',
                  icon: Icons.pause_rounded,
                  onPressed: onPause,
                )
              : _SecondaryButton(
                  key: const ValueKey('resume'),
                  label: 'RESUME',
                  icon: Icons.play_arrow_rounded,
                  onPressed: onResume,
                ),
        ),
        const SizedBox(width: 20),
        AnimatedOpacity(
          opacity: isRunning ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _PrimaryButton(
            label: 'SAVE',
            icon: Icons.save_rounded,
            onPressed: isRunning ? null : onSave,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.textTertiary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
