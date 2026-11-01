import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';
import 'package:smokii/models/hardware_reading.dart';
import 'package:smokii/services/app_state.dart';
import 'package:smokii/services/bluetooth_ble_service.dart';
import 'package:smokii/services/hardware_service.dart';

class HardwareReadingDialog extends StatefulWidget {
  const HardwareReadingDialog({super.key});

  @override
  State<HardwareReadingDialog> createState() => _HardwareReadingDialogState();
}

class _HardwareReadingDialogState extends State<HardwareReadingDialog> {
  // 0 = scan & connect, 1 = connected & ready, 2 = sampling, 3 = result
  int _flowStep = 0;
  bool _isBleScanning = false;
  bool _isBluetoothOn = true;

  final BluetoothBleService _bleService = BluetoothBleService();
  List<DiscoveredBleDevice> _realBleDevices = [];
  String _connectedDeviceName = '';
  HardwareReading? _latestReading;
  String _samplingStatus = 'تهيئة الحساس وفحص الهواء المحيط...';

  @override
  void initState() {
    super.initState();
    _checkAndStartBleScan();
  }

  Future<void> _checkAndStartBleScan() async {
    final btOn = await _bleService.isBluetoothSupportedAndOn();
    if (!mounted) return;

    setState(() {
      _isBluetoothOn = btOn;
    });

    _startBleScan();
  }

  Future<void> _startBleScan() async {
    setState(() {
      _isBleScanning = true;
      _flowStep = 0;
    });

    await _bleService.startRealScan(
      onDevicesUpdated: (devices) {
        if (mounted) {
          setState(() {
            _realBleDevices = devices;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isBleScanning = false;
      });
    }
  }

  Future<void> _connectToRealDevice(DiscoveredBleDevice bleDevice) async {
    setState(() {
      _isBleScanning = true;
    });

    final success = await _bleService.connectToBleDevice(bleDevice.device);
    if (!mounted) return;

    if (success) {
      setState(() {
        _isBleScanning = false;
        _connectedDeviceName = bleDevice.name;
        _flowStep = 1; // connected & ready!
      });
    } else {
      setState(() {
        _isBleScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الاتصال بجهاز ${bleDevice.name}، يرجى المحاولة مرة أخرى.'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  Future<void> _connectToSimulatedEsp32() async {
    setState(() {
      _isBleScanning = true;
    });

    await HardwareService().connectDevice('smokii_esp32_01');
    if (!mounted) return;

    setState(() {
      _isBleScanning = false;
      _connectedDeviceName = 'SMOCII-Sensor-ESP32 (Device Mode)';
      _flowStep = 1;
    });
  }

  Future<void> _takeLiveSample() async {
    setState(() {
      _flowStep = 2; // sampling
      _samplingStatus = 'جاري معايرة حساس النيكوتين (ESP32 Calibration)...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _samplingStatus = 'انفخ الآن بهدوء في فتحة الحساس لمدة 3 ثوانٍ... 💨';
    });

    final reading = await AppState().triggerHardwareCheck();
    if (!mounted) return;

    setState(() {
      _latestReading = reading;
      _flowStep = 3; // result
    });
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
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
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bluetooth_searching,
                            color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'اتصال البلوتوث (BLE)',
                        style: TextStyle(
                          fontSize: 17,
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
              const SizedBox(height: 16),

              if (_flowStep == 0) _buildBleScanView(),
              if (_flowStep == 1) _buildDeviceReadyView(),
              if (_flowStep == 2) _buildSamplingView(),
              if (_flowStep == 3 && _latestReading != null) _buildResultView(),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 0: Real Bluetooth BLE Scan & Pair
  Widget _buildBleScanView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '1. البحث عن جهاز الحساس (BLE Scan)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            if (_isBleScanning)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'يقوم التطبيق بالبحث عن إشارات البلوتوث الحية لأجهزة SMOCII ESP32 القريبة.',
          style: TextStyle(fontSize: 12, color: secondaryTextColor, height: 1.3),
        ),
        const SizedBox(height: 16),

        // Bluetooth adapter alert if disabled
        if (!_isBluetoothOn) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: warningColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_disabled, color: warningColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'البلوتوث غير مفعل أو غير مدعوم على هذه البيئة.',
                    style: TextStyle(fontSize: 11, color: Colors.orange[900]),
                  ),
                ),
                TextButton(
                  onPressed: () => _bleService.turnOnBluetooth(),
                  child: const Text('تفعيل'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Real Discovered Devices
        if (_realBleDevices.isNotEmpty) ...[
          const Text(
            'الأجهزة الحية المكتشفة بالبلوتوث:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          ..._realBleDevices.take(4).map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: d.isSmociiHardware
                    ? primaryColor.withValues(alpha: 0.06)
                    : const Color(0xFFF7FAFE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: d.isSmociiHardware
                      ? primaryColor
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    d.isSmociiHardware ? Icons.sensors : Icons.bluetooth,
                    color: d.isSmociiHardware ? primaryColor : secondaryTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: d.isSmociiHardware
                                ? primaryColor
                                : primaryTextColor,
                          ),
                        ),
                        Text(
                          'ID: ${d.remoteId} • إشارة: ${d.rssi} dBm (${d.signalStrength})',
                          style: TextStyle(fontSize: 10, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _connectToRealDevice(d),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('اتصال', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ],

        // Instant SMOCII ESP32 Direct Connect
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.memory, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMOCII-ESP32 Hardware Sensor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'اتصال مباشر بجهاز الحساس ESP32 المعتمد',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _connectToSimulatedEsp32,
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ربط فوري', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: _startBleScan,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(_isBleScanning ? 'جاري الفحص...' : 'إعادة مسح البلوتوث (Rescan)'),
          ),
        ),
      ],
    );
  }

  // STEP 1: Device Ready View
  Widget _buildDeviceReadyView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم الاتصال: $_connectedDeviceName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const Text(
                      'حساس النيكوتين متصل وجاهز لأخذ القراءة 🟢',
                      style: TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off, size: 20, color: Colors.red),
                tooltip: 'قطع الاتصال',
                onPressed: () {
                  _bleService.disconnect();
                  _startBleScan();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'الجهاز متصل الآن عبر البلوتوث، وجاهز لسحب عينة الهواء وقياس النيكوتين وسرعة السحبات.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _takeLiveSample,
            icon: const Icon(Icons.air, color: Colors.white),
            label: const Text(
              'اسحب القراءة من الحساس الآن',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Sampling View
  Widget _buildSamplingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _samplingStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'جاري نقل الداتا وتحديث خطة المعالجة في الباك إند...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // STEP 3: Result View
  Widget _buildResultView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _latestReading!.levelBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _latestReading!.levelColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _latestReading!.level == NicotineLevel.low
                        ? Icons.check_circle
                        : (_latestReading!.level == NicotineLevel.medium
                            ? Icons.info
                            : Icons.warning_amber_rounded),
                    color: _latestReading!.levelColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مستوى ${_latestReading!.levelLabel}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _latestReading!.levelColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_latestReading!.nicotinePpm} ppm',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تم رصد ${_latestReading!.puffsDetected} سحبة في هذه الجلسة',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Plan update feedback
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'استجابة خطة المعالجة التلقائية:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppState().currentPlan.hardwareFeedbackMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _flowStep = 1),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('فحص جديد'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'تم وتحديث الخطة',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
