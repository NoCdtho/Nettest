import 'package:flutter/material.dart';
import 'wifi_info_page.dart';
import 'network_strength_page.dart';
import 'packet_loss_page.dart';
import 'secure_network_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // light background like first UI
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ GRADIENT HEADER (like first code)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.network_check, size: 80, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    "Network Test App",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Check WiFi performance & security",
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ✅ BUTTONS SECTION (UNCHANGED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _infoCard(
                    context,
                    Icons.wifi,
                    "WiFi Information",
                    "SSID, BSSID, Encryption",
                    Colors.green,
                    const WiFiInfoPage(),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    context,
                    Icons.signal_cellular_alt,
                    "Network Strength",
                    "RSSI & Signal Quality",
                    Colors.blue,
                    const NetworkStrengthPage(),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    context,
                    Icons.show_chart,
                    "Packet Loss",
                    "Network Stability",
                    Colors.orange,
                    const PacketLossPage(),
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    context,
                    Icons.security,
                    "Secure Network",
                    "Detect Vulnerabilities",
                    Colors.red,
                    const SecureNetworkPage(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔒 BUTTON DESIGN — NOT CHANGED
  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Widget page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
