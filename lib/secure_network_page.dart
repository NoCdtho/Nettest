import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class SecureNetworkPage extends StatefulWidget {
  const SecureNetworkPage({super.key});

  @override
  State<SecureNetworkPage> createState() => _SecureNetworkPageState();
}

class _SecureNetworkPageState extends State<SecureNetworkPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  bool isConnected = false;
  bool isScanning = false;

  String ssid = "-";
  String bssid = "-";
  String deviceIp = "-";


  String status = "Not scanned";
  List<String> reasons = [];

  @override
  void initState() {
    super.initState();
    _loadWifiInfo();
  }

  Future<void> _loadWifiInfo() async {
    try {
      final connected = await _channel.invokeMethod('isWifiConnected');
      if (!connected) {
        setState(() {
          isConnected = false;
        });
        return;
      }

      final info = await _channel.invokeMethod('getCurrentWifiInfo');
      setState(() {
        isConnected = true;
        ssid = info['ssid'] ?? "-";
        bssid = info['bssid'] ?? "-";
        deviceIp = info['ipAddress'] ?? "-";
      });

      debugPrint("=== WiFi Info Loaded ===");
      debugPrint("SSID: $ssid");
      debugPrint("Device IP: $deviceIp");
    } catch (e) {
      debugPrint("Error loading WiFi info: $e");
      setState(() => isConnected = false);
    }
  }

  Future<void> _scanNetwork() async {
    if (!isConnected || deviceIp == "-" ) {
      _showMessage("Cannot scan: Missing network information");
      return;
    }

    setState(() {
      isScanning = true;
      status = "Scanning";
      reasons = [];
    });

    // FIXED: Match backend parameter names exactly
    final uri = Uri.parse(
      "http://10.104.50.86:8000/alerts/scan-network"
      "?device_ip=$deviceIp"           // CHANGED: ip → device_ip
      // "&gateway_ip=$gatewayIp"         // CHANGED: Added gateway_ip
      "&ssid=${Uri.encodeComponent(ssid)}"
      "&bssid=${Uri.encodeComponent(bssid)}",
    );

    debugPrint("=== Sending Scan Request ===");
    debugPrint("URL: $uri");

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          status = data['status'] ?? "ERROR";
          reasons = List<String>.from(data['reasons'] ?? []);
        });

        _showMessage("Scan complete: $status");
      } else {
        setState(() {
          status = "ERROR";
          reasons = ["Server error: ${response.statusCode}", response.body];
        });
      }
    } on Exception catch (e) {
      debugPrint("Scan error: $e");
      setState(() {
        status = "ERROR";
        reasons = ["Connection failed: ${e.toString()}"];
      });
      _showMessage("Failed to reach backend");
    } finally {
      setState(() => isScanning = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Security Scan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWifiInfo,
            tooltip: "Refresh network info",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWifiInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConnected
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? "Connected to WiFi" : "Not connected",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Connected Network",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _infoRow("SSID", ssid, Icons.wifi_tethering),
                _infoRow("BSSID", bssid, Icons.router),
                _infoRow("Device IP", deviceIp, Icons.phone_android),
    

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isConnected && !isScanning ? _scanNetwork : null,
                    icon: isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.security),
                    label: Text(
                      isScanning ? "Scanning Network..." : "Scan Network",
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (!isConnected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Connect to WiFi to enable scanning",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                const Text(
                  "Scan Result",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _resultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    Color color;
    IconData icon;
    switch (status) {
      case "OK":
        color = Colors.green;
        icon = Icons.verified_user;
        break;
      case "WARNING":
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case "DANGER":
        color = Colors.red;
        icon = Icons.dangerous;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 22,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
            ),
          ],
          if (status == "DANGER" || status == "WARNING") ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "⚠️ Avoid entering passwords or sensitive data",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}