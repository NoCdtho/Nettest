import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WiFiInfoPage extends StatefulWidget {
  const WiFiInfoPage({super.key});

  @override
  State<WiFiInfoPage> createState() => _WiFiInfoPageState();
}

class _WiFiInfoPageState extends State<WiFiInfoPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  bool isScanning = false;
  bool isConnected = false;
  bool isLoading = true;

  // Current WiFi Info
  String ssid = "Not Connected";
  String bssid = "-";
  String ipAddress = "-";
  int linkSpeed = 0;
  int frequency = 0;
  int signalLevel = -100;

  // Available Networks
  List<Map<String, dynamic>> availableNetworks = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentWiFiInfo();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadCurrentWiFiInfo() async {
    try {
      final bool connected = await _channel.invokeMethod('isWifiConnected');

      if (connected) {
        final dynamic info = await _channel.invokeMethod('getCurrentWifiInfo');

        if (info != null && mounted) {
          setState(() {
            isConnected = true;
            ssid = info['ssid']?.toString() ?? 'Unknown';
            bssid = info['bssid']?.toString() ?? '-';
            ipAddress = info['ipAddress']?.toString() ?? '-';
            linkSpeed = info['linkSpeed'] as int? ?? 0;
            frequency = info['frequency'] as int? ?? 0;
            signalLevel = info['rssi'] as int? ?? -100;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading WiFi info: $e");
      if (mounted) {
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  Future<void> _scanNetworks() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    try {
      final dynamic networks = await _channel.invokeMethod('scanWifiNetworks');

      if (mounted && networks != null) {
        final List<dynamic> networkList = networks as List<dynamic>;

        setState(() {
          availableNetworks = networkList.map((network) {
            return {
              'ssid': network['ssid']?.toString() ?? 'Hidden Network',
              'bssid': network['bssid']?.toString() ?? '',
              'level': network['level'] as int? ?? -100,
              'frequency': network['frequency'] as int? ?? 0,
              'capabilities': network['capabilities']?.toString() ?? '',
            };
          }).toList();

          // Sort by signal strength
          availableNetworks.sort(
            (a, b) => (b['level'] as int).compareTo(a['level'] as int),
          );
        });
      }
    } catch (e) {
      debugPrint("Error scanning networks: $e");
    }

    if (mounted) {
      setState(() {
        isScanning = false;
      });
    }
  }

  int _levelToPercent(int level) {
    if (level <= -90) return 0;
    if (level >= -40) return 100;
    return ((level + 90) * 2).clamp(0, 100);
  }

  String _getSecurityType(String capabilities) {
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return 'Open';
  }

  Widget _buildSignalBars(int level) {
    final percent = _levelToPercent(level);
    final activeBars = (percent / 25).ceil();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 6,
          height: 8.0 + index * 4,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < activeBars ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  int _getChannelFromFrequency(int freq) {
    if (freq >= 2412 && freq <= 2484) {
      return (freq - 2412) ~/ 5 + 1;
    } else if (freq >= 5170 && freq <= 5825) {
      return (freq - 5170) ~/ 5 + 34;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'WiFi Information',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentWiFiInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CURRENT CONNECTION
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
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
                    Row(
                      children: [
                        const Icon(Icons.wifi, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Current WiFi Connection',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isConnected ? 'Connected' : 'Off',
                              style: TextStyle(
                                color: isConnected ? Colors.green : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildInfoRow(
                      'Network Name (SSID)',
                      ssid,
                      Icons.wifi_tethering,
                    ),
                    _buildInfoRow(
                      'MAC Address (BSSID)',
                      bssid,
                      Icons.location_on_outlined,
                    ),
                    _buildInfoRow('IP Address', ipAddress, Icons.language),
                    _buildInfoRow(
                      'Frequency',
                      frequency > 0
                          ? '${(frequency / 1000).toStringAsFixed(1)} GHz'
                          : '-',
                      null,
                    ),
                    _buildInfoRow(
                      'Channel',
                      frequency > 0
                          ? _getChannelFromFrequency(frequency).toString()
                          : '-',
                      null,
                    ),
                    _buildInfoRow(
                      'Security',
                      isConnected ? 'WPA3-Personal' : '-',
                      Icons.lock,
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Link Speed and Signal Level
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$linkSpeed Mbps',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Link Speed',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$signalLevel dBm',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Signal Level',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // AVAILABLE NETWORKS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Available Networks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: isScanning ? null : _scanNetworks,
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text(isScanning ? 'Scanning...' : 'Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Nearby WiFi networks',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              const SizedBox(height: 8),

              // SCANNING INDICATOR
              if (isScanning)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // NETWORK LIST
              if (!isScanning && availableNetworks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No networks found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!isScanning && availableNetworks.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableNetworks.length,
                  itemBuilder: (context, index) {
                    final network = availableNetworks[index];
                    final isCurrentNetwork = network['ssid'] == ssid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentNetwork
                            ? Colors.blue.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentNetwork
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildSignalBars(network['level']),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        network['ssid'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCurrentNetwork
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrentNetwork)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getSecurityType(network['capabilities']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_levelToPercent(network['level'])}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
