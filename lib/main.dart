import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DnsApp());
}

class DnsApp extends StatelessWidget {
  const DnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HardDnsPage(),
    );
  }
}

class HardDnsPage extends StatefulWidget {
  const HardDnsPage({super.key});

  @override
  State<HardDnsPage> createState() => _HardDnsPageState();
}

class _HardDnsPageState extends State<HardDnsPage> {
  String output = "Press button to run advanced DNS analysis";

  final List<String> domains = [
    "google.com",
    "cloudflare.com",
    "amazon.com",
    "facebook.com",
  ];

  Future<void> runHardDnsCheck() async {
    int riskScore = 0;
    String log = "";

    for (final domain in domains) {
      try {
        // 1️⃣ SYSTEM DNS (Android / Wi-Fi / ISP)
        final systemResults = await InternetAddress.lookup(domain);
        final systemIps = systemResults.map((e) => e.address).toSet();

        // 2️⃣ TRUSTED DNS (Google DoH)
        final dohResponse = await http.get(
          Uri.parse("https://dns.google/resolve?name=$domain&type=A"),
        );

        final json = jsonDecode(dohResponse.body);
        final answers = json["Answer"] ?? [];
        final trustedIps = <String>{};

        for (var a in answers) {
          trustedIps.add(a["data"]);
        }

        // 3️⃣ IP SAFETY CHECK
        bool unsafeFound = false;
        for (final ip in systemIps) {
          if (isUnsafeIp(ip)) {
            unsafeFound = true;
            riskScore += 2;
          }
        }

        // 4️⃣ DNS MISMATCH CHECK
        final dnsMatch = systemIps.intersection(trustedIps).isNotEmpty;

        if (!dnsMatch) {
          riskScore += 2;
        }

        // 5️⃣ LOGGING
        log += "🌐 $domain\n";
        log += "System DNS  : $systemIps\n";
        log += "Trusted DNS : $trustedIps\n";

        if (unsafeFound && !dnsMatch) {
          log += "🚨 HIGH RISK (Unsafe IP + DNS mismatch)\n\n";
        } else if (!dnsMatch) {
          log += "⚠️ SUSPICIOUS (DNS mismatch)\n\n";
        } else {
          log += "✅ SAFE\n\n";
        }
      } catch (e) {
        riskScore += 1;
        log += "❌ $domain lookup failed\n\n";
      }
    }

    // 6️⃣ FINAL VERDICT
    String status;
    String confidence;

    if (riskScore >= 6) {
      status = "🔴 DNS HIJACKING LIKELY";
      confidence = "HIGH";
    } else if (riskScore >= 3) {
      status = "🟡 NETWORK SUSPICIOUS";
      confidence = "MEDIUM";
    } else {
      status = "🟢 DNS SAFE";
      confidence = "HIGH";
    }

    setState(() {
      output =
          "FINAL STATUS: $status\n"
          "Confidence : $confidence\n"
          "Risk Score : $riskScore\n\n"
          "$log";
    });
  }

  // 🔐 UNSAFE IP RULES (CRITICAL SECURITY LOGIC)
  bool isUnsafeIp(String ip) {
    if (ip.startsWith("127.")) return true; // Loopback
    if (ip.startsWith("10.")) return true; // Private
    if (ip.startsWith("192.168.")) return true; // Private
    if (ip.startsWith("169.254.")) return true; // Link-local

    if (ip.startsWith("172.")) {
      final second = int.tryParse(ip.split(".")[1]) ?? 0;
      if (second >= 16 && second <= 31) return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advanced DNS Security Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: runHardDnsCheck,
              child: const Text("Run Advanced DNS Check"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(output, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
