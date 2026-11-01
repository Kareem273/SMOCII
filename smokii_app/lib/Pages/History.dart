import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/services/app_state.dart';
import 'package:smokii/widgets/hardware_reading_dialog.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final readings = _appState.readingHistory;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sensor History & Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryTextColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const HardwareReadingDialog(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'TOTAL SESSIONS',
                        value: '${readings.length}',
                        icon: Icons.history,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'CLEAN RATIO',
                        value: '84%',
                        icon: Icons.eco,
                        color: successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'STREAK',
                        value: '${_appState.streakDays} Days',
                        icon: Icons.local_fire_department,
                        color: warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Weekly Trend Visualizer Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: pirmaryColorElementBG,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'WEEKLY NICOTINE INTENSITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: secondaryTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Trending Down (-32%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: successColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Day bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDayBar('Mon', 26.0, NicotineLevel.medium),
                          _buildDayBar('Tue', 18.0, NicotineLevel.medium),
                          _buildDayBar('Wed', 12.0, NicotineLevel.low),
                          _buildDayBar('Thu', 14.0, NicotineLevel.low),
                          _buildDayBar('Fri', 22.0, NicotineLevel.medium),
                          _buildDayBar('Sat', 11.0, NicotineLevel.low),
                          _buildDayBar('Sun', _appState.latestReading.nicotinePpm, _appState.latestReading.level),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Log Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'COMPANION SENSOR READINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const HardwareReadingDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Check'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // List of readings
                ...readings.reversed.map((reading) => _buildReadingCard(reading)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pirmaryColorElementBG,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildDayBar(String day, double ppm, NicotineLevel level) {
    final heightRatio = (ppm / 40.0).clamp(0.2, 1.0);
    Color barColor;
    switch (level) {
      case NicotineLevel.low:
        barColor = successColor;
        break;
      case NicotineLevel.medium:
        barColor = warningColor;
        break;
      case NicotineLevel.high:
        barColor = dangerColor;
        break;
    }

    return Column(
      children: [
        Text(
          '${ppm.toInt()}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: 90 * heightRatio,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildReadingCard(HardwareReading reading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pirmaryColorElementBG,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reading.levelBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors,
              color: reading.levelColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reading.nicotinePpm} ppm (${reading.levelLabel})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      '${reading.timestamp.hour.toString().padLeft(2, '0')}:${reading.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reading.notes.isNotEmpty ? reading.notes : reading.deviceStatus,
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.battery_charging_full, size: 14, color: secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      '${reading.sensorBattery}%',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 14, color: secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(
                      '${reading.sessionDurationSeconds}s sampling',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
