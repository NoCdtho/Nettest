import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PacketLossPage extends StatefulWidget {
  const PacketLossPage({super.key});

  @override
  State<PacketLossPage> createState() => _PacketLossFrontPageState();
}

class _PacketLossFrontPageState extends State<PacketLossPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  bool isLoading = false;

  int packetsSent = 0;
  int packetsLost = 0;
  double packetLossPercent = 0.0;
  String networkStatus = "Unknown";

  Future<void> runPacketLossTest() async {
    const int count = 10;

    setState(() {
      isLoading = true;
      packetsSent = count;
      packetsLost = 0;
      packetLossPercent = 0;
      networkStatus = "Testing...";
    });

    try {
      final int lossPercent = await _channel.invokeMethod('pingTest', {
        'host': '8.8.8.8',
        'count': count,
      });

      packetsLost = ((lossPercent / 100) * packetsSent).round();
      packetLossPercent = lossPercent.toDouble();

      if (packetLossPercent == 0) {
        networkStatus = "Excellent";
      } else if (packetLossPercent <= 5) {
        networkStatus = "Good";
      } else if (packetLossPercent <= 15) {
        networkStatus = "Fair";
      } else {
        networkStatus = "Poor";
      }
    } catch (e) {
      networkStatus = "Test Failed";
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: const [
                  Icon(Icons.show_chart, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Packet Loss",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                "Network stability monitoring",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Loss %
              Text(
                "${packetLossPercent.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: packetLossPercent <= 5
                      ? Colors.green
                      : packetLossPercent <= 15
                      ? Colors.orange
                      : Colors.red,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                networkStatus,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Details
              _infoRow("Packets Sent", packetsSent.toString()),
              _infoRow("Packets Lost", packetsLost.toString()),
              _infoRow("Loss %", "${packetLossPercent.toStringAsFixed(1)} %"),

              const SizedBox(height: 30),

              // Button
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : runPacketLossTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Run Packet Loss Test",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
