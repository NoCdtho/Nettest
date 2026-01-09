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
  bool isMeasuring = false;

  int rssi = -100;
  int signalPercent = 0;
  double pingMs = 0;
  String quality = "";

  // ================= INIT =================

  @override
  void dispose() {
    super.dispose();
  }

  // ================= MAIN TEST =================

  Future<void> startTest() async {
    if (isMeasuring) return;

    final bool wifiConnected = await _isWifiConnected();
    debugPrint("wifi from kotlin = $wifiConnected");
    if (!wifiConnected) {
      setState(() {
        isOffline = true;
        hasTested = false;
        isMeasuring = false;
      });
      return;
    }

    setState(() {
      isOffline = false;
      hasTested = false;
      isMeasuring = true;
    });

    // Allow RSSI to stabilize
    await Future.delayed(const Duration(milliseconds: 800));

    rssi = await _getStableRssi();
    pingMs = await _measurePing();

    signalPercent = _rssiToPercent(rssi);
    _calculateQuality();

    setState(() {
      isMeasuring = false;
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
      backgroundColor: const Color(0xFFF4F7FC),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: const [
                  Icon(Icons.wifi, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Network Strength",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // STATUS
              Text(
                isOffline
                    ? "You are not connected to Wi-Fi"
                    : isMeasuring
                    ? "Measuring network…"
                    : hasTested
                    ? "Current signal quality: $quality"
                    : "Waiting for measurement",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // LOADING
              if (isMeasuring) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "Please wait…",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],

              // RESULT
              if (hasTested && !isMeasuring && !isOffline) ...[
                Row(
                  children: [
                    Icon(
                      Icons.signal_wifi_4_bar,
                      size: 36,
                      color: _signalColor(signalPercent),
                    ),
                    const SizedBox(width: 12),

                    // Bars
                    Row(
                      children: List.generate(4, (index) {
                        final activeBars = (signalPercent / 25).ceil();
                        return Container(
                          width: 8,
                          height: 12 + index * 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: index < activeBars
                                ? _signalColor(signalPercent)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(width: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Signal Strength",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "$signalPercent%",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _signalColor(signalPercent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text("📶 RSSI: $rssi dBm"),
                Text("📡 LANTENCY: ${pingMs.toStringAsFixed(1)} ms"),
              ],

              const SizedBox(height: 24),

              // BUTTON
              Center(
                child: SizedBox(
                  width: 220,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: startTest,
                    child: const Text("Test Network Speed"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
