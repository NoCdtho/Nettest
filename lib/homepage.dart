import 'package:flutter/material.dart';
import 'packet_loss_page.dart';
import 'network_strength_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.network_check, size: 90, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Network Test App",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check network strength & packet loss easily",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "strength") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NetworkStrengthPage(),
                    ),
                  );
                } else if (value == "packet") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PacketLossPage()),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "strength",
                  child: ListTile(
                    leading: Icon(Icons.signal_cellular_alt),
                    title: Text("Network Strength Test"),
                  ),
                ),
                PopupMenuItem(
                  value: "packet",
                  child: ListTile(
                    leading: Icon(Icons.warning_amber),
                    title: Text("Packet Loss Test"),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "START TEST",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
