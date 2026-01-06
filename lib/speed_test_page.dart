import 'package:flutter/material.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Internet Speed Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {}, // logic later
              child: const Text("Start Speed Test"),
            ),
            const SizedBox(height: 20),
            _resultCard("Download Speed", "-- Mbps"),
            _resultCard("Upload Speed", "-- Mbps"),
            _resultCard("Ping", "-- ms"),
            _resultCard("Jitter", "-- ms"),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String title, String value) {
    return Card(
      child: ListTile(title: Text(title), trailing: Text(value)),
    );
  }
}
