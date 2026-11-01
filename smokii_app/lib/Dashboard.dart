import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';
import 'package:smokii/Pages/History.dart';
import 'package:smokii/Pages/Quit-Plan.dart';
import 'package:smokii/Pages/ai_coach_page.dart';
import 'package:smokii/Getinfo.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/models/treatment_plan_model.dart';
import 'package:smokii/services/app_state.dart';
import 'package:smokii/widgets/craving_sos_dialog.dart';
import 'package:smokii/widgets/hardware_reading_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final AppState _appState = AppState();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateUpdate);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateUpdate);
    super.dispose();
  }

  void _onStateUpdate() {
    if (mounted) setState(() {});
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      setState(() => _currentNavIndex = 0);
    } else if (index == 1) {
      _navigateToQuitPlan();
    } else if (index == 2) {
      _navigateToAiCoach();
    } else if (index == 3) {
      _navigateToHistory();
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryPage()),
    );
  }

  void _navigateToQuitPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuitPlanPage()),
    );
  }

  void _navigateToAiCoach() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiCoachPage()),
    );
  }

  void _navigateToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Getinfo()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = _appState.latestReading;
    final plan = _appState.currentPlan;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Hello, ${_appState.userName}",
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const Text(
              "Track today. Reduce tomorrow.",
              style: TextStyle(fontSize: 16, color: secondaryTextColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: dangerColor, size: 26),
            tooltip: 'Craving SOS',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CravingSosDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: primaryColor, size: 26),
            tooltip: 'AI Assessment',
            onPressed: _navigateToAssessment,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Device Pairing Status Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const HardwareReadingDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _appState.isDeviceConnected
                            ? Colors.green.withValues(alpha: 0.1)
                            : primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _appState.isDeviceConnected
                              ? Colors.green.withValues(alpha: 0.3)
                              : primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _appState.isDeviceConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_searching,
                            size: 18,
                            color: _appState.isDeviceConnected
                                ? Colors.green
                                : primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _appState.isDeviceConnected
                                  ? 'الجهاز متصل: ${_appState.connectedDeviceName} (${_appState.connectedDeviceBattery}%)'
                                  : 'اضغط هنا للاتصال بجهاز الحساس (ESP32) أولاً',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _appState.isDeviceConnected
                                    ? Colors.green[800]
                                    : primaryColor,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: secondaryTextColor),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NicotineLevelCard(
                  reading: reading,
                  streakDays: _appState.streakDays,
                  lowDaysCount: _appState.lowDaysCount,
                  avgLevel: _appState.avgLevel,
                  progressRatio: _appState.thisWeekProgress,
                  onStartCheck: () {
                    showDialog(
                      context: context,
                      builder: (context) => const HardwareReadingDialog(),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Quick Actions Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Action Cards Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          title: 'View History',
                          description: 'See trends, streaks,\nand sensor data.',
                          icon: Icons.history,
                          buttonText: 'Open',
                          onTap: _navigateToHistory,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionCard(
                          title: 'Quit Plan',
                          description: 'Step-by-step,\npersonalized.',
                          icon: Icons.track_changes,
                          buttonText: 'Today: ${plan.tasks.where((t) => !t.isCompleted).length} tasks',
                          onTap: _navigateToQuitPlan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Second row of actions: AI Coach & Craving SOS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          title: 'AI Coach',
                          description: '24/7 Companion &\ncraving support.',
                          icon: Icons.auto_awesome,
                          buttonText: 'Chat now',
                          onTap: _navigateToAiCoach,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionCard(
                          title: 'Craving SOS',
                          description: 'Ride the wave with\nthe 4 D\'s pacer.',
                          icon: Icons.shield_outlined,
                          buttonText: 'Emergency',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const CravingSosDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // TODAY Section Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TODAY'S PLAN ACTIONS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: secondaryTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToQuitPlan,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Today's Tasks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: plan.tasks.take(3).map((task) {
                      return _buildTodayTaskCard(task);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Quit Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTaskCard(PlanTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: pirmaryColorElementBG,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? successColor : secondaryTextColor,
            size: 24,
          ),
          onPressed: () => _appState.toggleTask(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: task.isCompleted ? secondaryTextColor : primaryTextColor,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: secondaryTextColor),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.timeOfDay,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class NicotineLevelCard extends StatelessWidget {
  final HardwareReading reading;
  final int streakDays;
  final int lowDaysCount;
  final String avgLevel;
  final double progressRatio;
  final VoidCallback onStartCheck;

  const NicotineLevelCard({
    super.key,
    required this.reading,
    required this.streakDays,
    required this.lowDaysCount,
    required this.avgLevel,
    required this.progressRatio,
    required this.onStartCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pirmaryColorElementBG,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT NICOTINE LEVEL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: reading.levelBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: reading.levelColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          reading.levelLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: reading.levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reading.nicotinePpm} ppm',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 104,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor),
                ),
                child: OutlinedButton.icon(
                  onPressed: onStartCheck,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    backgroundColor: primaryColor.withValues(alpha: 0.05),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stat Cards Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: _buildStatCard(
                    title: 'STREAK',
                    value: '$streakDays days',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: _buildStatCard(
                    title: 'LOW DAYS',
                    value: '$lowDaysCount',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: _buildStatCard(
                    title: 'AVG LEVEL',
                    value: avgLevel,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This week\'s progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
              ),
              Text(
                '${(progressRatio * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 14,
              backgroundColor: const Color(0xFFcfe3fc),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1479f5),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Higher means more "Low" days.',
            style: TextStyle(fontSize: 12, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String buttonText;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
    this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.96 : 1.0,
          _isPressed ? 0.96 : 1.0,
          1.0,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isPressed
              ? pirmaryColorElementBG.withValues(alpha: 0.8)
              : pirmaryColorElementBG,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.20 : 0.10),
              blurRadius: _isPressed ? 14 : 8,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: secondaryTextColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // Button
            Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.buttonText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
