import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool hasLocationPermission = false;

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
    await _checkAndRequestPermission();
    setState(() {
      isLoading = false;
    });
    
    // Auto-scan if permission granted
    if (hasLocationPermission) {
      await _scanNetworks();
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    debugPrint("Checking location permission...");
    
    // Check current status
    var status = await Permission.locationWhenInUse.status;
    debugPrint("Current permission status: $status");

    if (status.isGranted) {
      setState(() {
        hasLocationPermission = true;
      });
      return true;
    }

    // Request permission
    debugPrint("Requesting location permission...");
    status = await Permission.locationWhenInUse.request();
    debugPrint("Permission request result: $status");

    if (status.isGranted) {
      setState(() {
        hasLocationPermission = true;
      });
      _showMessage("Location permission granted!");
      return true;
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    } else {
      _showMessage("Location permission is required to scan WiFi networks");
      return false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is required to scan WiFi networks. '
          'Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
    if (isScanning) {
      debugPrint("Scan already in progress, skipping");
      return;
    }

    // Check permission before scanning
    if (!hasLocationPermission) {
      debugPrint("No location permission, requesting...");
      final granted = await _checkAndRequestPermission();
      if (!granted) {
        debugPrint("Permission not granted, cannot scan");
        return;
      }
    }

    debugPrint("=== STARTING NETWORK SCAN ===");
    
    setState(() {
      isScanning = true;
      availableNetworks.clear();
    });

    try {
      debugPrint("Calling scanWifiNetworks method...");
      
      final dynamic networks = await _channel.invokeMethod('scanWifiNetworks');
      
      debugPrint("Scan complete. Networks received: ${networks?.runtimeType}");
      debugPrint("Networks data: $networks");

      if (networks == null) {
        debugPrint("Networks is NULL");
        if (mounted) {
          setState(() {
            isScanning = false;
          });
        }
        return;
      }

      if (mounted) {
        final List<dynamic> networkList = networks as List<dynamic>;
        debugPrint("Found ${networkList.length} networks");

        // Debug each network
        for (var i = 0; i < networkList.length; i++) {
          debugPrint("Network $i: ${networkList[i]}");
        }

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
        
        debugPrint("Available networks after processing: ${availableNetworks.length}");
        
        if (availableNetworks.isEmpty) {
          debugPrint("WARNING: No networks found after scan.");
          _showMessage("No networks found. Make sure WiFi is enabled.");
        } else {
          debugPrint("SUCCESS: ${availableNetworks.length} networks available");
          _showMessage("Found ${availableNetworks.length} networks");
        }
      }
    } on PlatformException catch (e) {
      debugPrint("PlatformException: ${e.code} - ${e.message}");
      if (mounted) {
        String message = "Scan failed";
        if (e.code == 'PERMISSION_DENIED') {
          message = "Location permission required";
          setState(() {
            hasLocationPermission = false;
          });
        } else if (e.code == 'WIFI_DISABLED') {
          message = "Please enable WiFi";
        } else {
          message = "Error: ${e.message}";
        }
        _showMessage(message);
      }
    } catch (e, stackTrace) {
      debugPrint("ERROR scanning networks: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        _showMessage("Scan error: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
        debugPrint("=== SCAN COMPLETE ===");
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
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
        onRefresh: () async {
          await _loadCurrentWiFiInfo();
          if (hasLocationPermission) {
            await _scanNetworks();
          }
        },
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

              // PERMISSION WARNING
              if (!hasLocationPermission)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Permission Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enable location to scan WiFi networks',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _checkAndRequestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Grant', style: TextStyle(fontSize: 12)),
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
                      onPressed: (isScanning || !hasLocationPermission) ? null : _scanNetworks,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(isScanning ? 'Scanning...' : 'Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        disabledForegroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  hasLocationPermission 
                    ? 'Nearby WiFi networks' 
                    : 'Grant location permission to scan',
                  style: TextStyle(
                    color: hasLocationPermission ? Colors.grey : Colors.orange,
                    fontSize: 14,
                  ),
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
                        const SizedBox(height: 8),
                        Text(
                          hasLocationPermission ? 'Tap Scan to search' : 'Grant permission first',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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