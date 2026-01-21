import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NetworkStrengthPage extends StatefulWidget {
  const NetworkStrengthPage({super.key});

  @override
  State<NetworkStrengthPage> createState() => _NetworkStrengthPageState();
}

class _NetworkStrengthPageState extends State<NetworkStrengthPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  bool hasTested = false;
  bool isOffline = false;
  bool isScanning = false;
  bool showDetails = false;

  int rssi = -100;
  int signalPercent = 0;
  double pingMs = 0;
  String quality = "";

  Timer? _scanTimer;

  // ================= INIT =================

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  // ================= SCANNING CONTROL =================

  void startScanning() {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      hasTested = false;
    });

    _performScan();

    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _performScan();
    });
  }

  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;

    setState(() {
      isScanning = false;
    });
  }

  // ================= MAIN TEST =================

  Future<void> _performScan() async {
    final bool wifiConnected = await _isWifiConnected();
    debugPrint("wifi from kotlin = $wifiConnected");

    if (!wifiConnected) {
      setState(() {
        isOffline = true;
        hasTested = false;
      });
      return;
    }

    setState(() {
      isOffline = false;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    rssi = await _getStableRssi();
    pingMs = await _measurePing();

    signalPercent = _rssiToPercent(rssi);
    _calculateQuality();

    setState(() {
      hasTested = true;
    });
  }

  // ================= ANDROID CALLS =================

  Future<bool> _isWifiConnected() async {
    try {
      return await _channel.invokeMethod('isWifiConnected');
    } catch (_) {
      return false;
    }
  }

  Future<int> _getWifiRssi() async {
    try {
      return await _channel.invokeMethod('getWifiRssi');
    } catch (_) {
      return -100;
    }
  }

  Future<int> _getStableRssi() async {
    int value = await _getWifiRssi();
    if (value < -90) {
      await Future.delayed(const Duration(milliseconds: 400));
      value = await _getWifiRssi();
    }
    return value;
  }

  // ================= HTTP LATENCY =================

  Future<double> _measurePing() async {
    final stopwatch = Stopwatch()..start();
    try {
      final request = await HttpClient().getUrl(
        Uri.parse("https://www.google.com"),
      );
      await request.close();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds.toDouble();
    } catch (_) {
      return 999;
    }
  }

  // ================= CALCULATIONS =================

  int _rssiToPercent(int rssi) {
    if (rssi <= -90) return 0;
    if (rssi >= -40) return 100;
    return ((rssi + 90) * 2).clamp(0, 100);
  }

  void _calculateQuality() {
    if (signalPercent >= 75) {
      quality = "Excellent";
    } else if (signalPercent >= 50) {
      quality = "Good";
    } else if (signalPercent >= 30) {
      quality = "Fair";
    } else {
      quality = "Poor";
    }
  }

  Color _signalColor(int percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 50) return Colors.orange;
    if (percent >= 30) return Colors.deepOrange;
    return Colors.red;
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8EDF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Network Analyzer",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Monitor your network performance and WiFi connections",
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // MAIN CARD
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD HEADER
                    Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          color: isScanning ? Colors.blue : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Network Strength",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        // SHOW DETAILS TOGGLE
                        Text(
                          "Details",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: showDetails,
                            onChanged: (value) {
                              setState(() {
                                showDetails = value;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // STATUS
                    Text(
                      isOffline
                          ? "You are not connected to Wi-Fi"
                          : hasTested
                          ? "Current signal quality: $quality"
                          : "Press Start to begin scanning",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 32),

                    // SIGNAL BARS + PROGRESS
                    if (hasTested && !isOffline) ...[
                      Row(
                        children: [
                          // Animated signal bars
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(4, (index) {
                              final activeBars = (signalPercent / 25).ceil();
                              return Container(
                                width: 16,
                                height: 20.0 + index * 12,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: index < activeBars
                                      ? _signalColor(signalPercent)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(width: 20),

                          // Progress bar and percentage
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Signal Strength",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    Text(
                                      "$signalPercent%",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _signalColor(signalPercent),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: signalPercent / 100,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _signalColor(signalPercent),
                                    ),
                                    minHeight: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // DETAILS SECTION
                      if (showDetails) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                "RSSI",
                                "$rssi dBm",
                                Icons.signal_cellular_alt,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                "Latency",
                                "${pingMs.toStringAsFixed(1)} ms",
                                Icons.speed,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],

                    const Spacer(),

                    // SCANNING INDICATOR
                    if (isScanning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Scanning...",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isScanning ? null : startScanning,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Start",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isScanning ? stopScanning : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Stop",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
