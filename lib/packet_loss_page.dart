import 'package:flutter/material.dart';

class PacketLossPage extends StatelessWidget {
  const PacketLossPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Packet Loss Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {}, // logic later
              child: const Text("Start Packet Loss Test"),
            ),
            const SizedBox(height: 20),
            _resultCard("Packets Sent", "--"),
            _resultCard("Packets Lost", "--"),
            _resultCard("Packet Loss %", "-- %"),
            _resultCard("Network Status", "Unknown"),
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
