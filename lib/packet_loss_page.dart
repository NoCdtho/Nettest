import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PacketLossPage extends StatefulWidget {
  const PacketLossPage({super.key});

  @override
  State<PacketLossPage> createState() => _PacketLossPageState();
}

class _PacketLossPageState extends State<PacketLossPage> {
  static const MethodChannel _channel = MethodChannel('network_tools');

  String result = "Not tested";
  bool isLoading = false;

  Future<void> runPing() async {
    setState(() => isLoading = true);

    try {
      final int loss = await _channel.invokeMethod('pingTest', {
        'host': '8.8.8.8',
        'count': 10,
      });

      setState(() {
        result = "Packet loss: $loss%";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = "Ping failed";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Packet Loss Test")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : runPing,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Run Ping Test"),
            ),
          ],
        ),
      ),
    );
  }
}
