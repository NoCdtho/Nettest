import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PacketLossPage extends StatefulWidget {
  const PacketLossPage({super.key});

  @override
  State<PacketLossPage> createState() => _PacketLossPageState();
}

class _PacketLossPageState extends State<PacketLossPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  bool isLoading = false;

  int packetsSent = 0;
  int packetsLost = 0;
  double packetLossPercent = 0;
  String networkStatus = "Unknown";

  Future<void> runPing() async {
    setState(() {
      isLoading = true;
      packetsSent = 10;
    });

    try {
      final int lossPercent = await _channel.invokeMethod('pingTest', {
        'host': '8.8.8.8',
        'count': 10,
      });

      packetsLost = ((lossPercent / 100) * packetsSent).round();
      packetLossPercent = lossPercent.toDouble();

      if (packetLossPercent == 0) {
        networkStatus = "Excellent";
      } else if (packetLossPercent <= 5) {
        networkStatus = "Good";
      } else if (packetLossPercent <= 15) {
        networkStatus = "Average";
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
      appBar: AppBar(title: const Text("Packet Loss Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : runPing,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Start Packet Loss Test"),
            ),
            const SizedBox(height: 20),

            _resultCard("Packets Sent", packetsSent.toString()),
            _resultCard("Packets Lost", packetsLost.toString()),
            _resultCard(
              "Packet Loss %",
              "${packetLossPercent.toStringAsFixed(1)} %",
            ),
            _resultCard("Network Status", networkStatus),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String title, String value) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
