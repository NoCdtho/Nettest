import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PingPage());
  }
}

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
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
      });
    } catch (e) {
      setState(() {
        result = "Ping failed";
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
              onPressed: runPing,
              child: const Text("Run Ping Test"),
            ),
          ],
        ),
      ),
    );
  }
}
