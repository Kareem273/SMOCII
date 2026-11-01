import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';

class CravingSosDialog extends StatefulWidget {
  const CravingSosDialog({super.key});

  @override
  State<CravingSosDialog> createState() => _CravingSosDialogState();
}

class _CravingSosDialogState extends State<CravingSosDialog>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 300; // 5 minutes
  Timer? _timer;
  bool _isTimerRunning = true;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  String _breathingText = 'Breathe in...';

  @override
  void initState() {
    super.initState();
    _startTimer();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _breathingText = 'Hold...';
          });
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _breathingText = 'Slowly exhale...';
              });
              _breathingController.reverse();
            }
          });
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _breathingText = 'Breathe in...';
          });
          _breathingController.forward();
        }
      });

    _breathingController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: pirmaryColorElementBG,
          borderRadius: BorderRadius.circular(24),
          boxShadow: cardShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dangerColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: dangerColor, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Craving SOS Shield',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Remember: Craving intensity peaks in 3 minutes then drops. Ride the wave with the 4 D\'s technique.',
                style: TextStyle(fontSize: 13, color: secondaryTextColor),
              ),
              const SizedBox(height: 20),

              // Timer Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. DELAY (5 MINUTE RULE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_isTimerRunning) {
                            _timer?.cancel();
                            _isTimerRunning = false;
                          } else {
                            _startTimer();
                            _isTimerRunning = true;
                          }
                        });
                      },
                      icon: Icon(
                        _isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: primaryColor,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Deep Breathe Interactive Circle
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '2. DEEP BREATHE (4-7-8 PACER)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFF64B5F6),
                              Color(0xFF1479F5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _breathingText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Drink Water & 4. Distract
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildStepRow(
                      icon: Icons.water_drop_outlined,
                      color: Colors.blue,
                      title: '3. Drink Cold Water',
                      subtitle: 'Sip slowly to activate vagus nerve & soothe oral fixation.',
                    ),
                    const Divider(height: 16),
                    _buildStepRow(
                      icon: Icons.directions_walk_outlined,
                      color: Colors.green,
                      title: '4. Distract & Relocate',
                      subtitle: 'Walk out of the room, wash your hands, or call a friend.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Craving defeated! Your resistance strength increased.'),
                        backgroundColor: successColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'I Rode the Wave (Craving Passed)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
