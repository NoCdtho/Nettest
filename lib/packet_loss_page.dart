import 'dart:async';
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
  bool isRunning = false;
  bool showDetails = false;
  Timer? _timer;

  int packetsSent = 0;
  int packetsLost = 0;
  double packetLossPercent = 0.0;
  String networkStatus = "Unknown";

  // For chart data - storing historical packet loss
  List<double> lossHistory = [];
  List<String> timeLabels = [];

  @override
  void initState() {
    super.initState();
  }

  void startAutoTest() {
    if (isRunning) return;

    isRunning = true;

    runPacketLossTest();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isLoading && mounted) {
        await runPacketLossTest();
      }
    });

    setState(() {});
  }

  void stopAutoTest() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    isLoading = false;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

      // Add to history for chart
      lossHistory.add(packetLossPercent);
      final now = DateTime.now();
      timeLabels.add("${now.hour}:${now.minute.toString().padLeft(2, '0')}");

      // Keep only last 10 data points
      if (lossHistory.length > 10) {
        lossHistory.removeAt(0);
        timeLabels.removeAt(0);
      }

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

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Color _getStatusColor() {
    if (packetLossPercent <= 5) return Colors.green;
    if (packetLossPercent <= 15) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  //New back buttom added here
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width:12),
                  const Icon(Icons.show_chart, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Packet Loss",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Network stability monitoring",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SHOW DETAILS TOGGLE
                  Text(
                    "Details",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: showDetails,
                      onChanged: (value) {
                        setState(() {
                          showDetails = value;
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PACKET LOSS PERCENTAGE
                    Text(
                      "${packetLossPercent.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      networkStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // CHART
                    if (lossHistory.isNotEmpty) _buildChart(),

                    // DETAILS SECTION
                    if (showDetails) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        "Packets Sent",
                        packetsSent.toString(),
                        Icons.send,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        "Packets Lost",
                        packetsLost.toString(),
                        Icons.error_outline,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        "Loss Percentage",
                        "${packetLossPercent.toStringAsFixed(1)}%",
                        Icons.trending_down,
                        Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // SCANNING INDICATOR
            if (isRunning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Monitoring...",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isRunning ? null : startAutoTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Start",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isRunning ? stopAutoTest : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Stop",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: LineChartPainter(dataPoints: lossHistory, labels: timeLabels),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;

  LineChartPainter({required this.dataPoints, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final maxLoss = dataPoints
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, 100.0);
    final spacing = size.width / (dataPoints.length - 1).clamp(1, 100);

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final y = size.height - (dataPoints[i] / maxLoss * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < points.length; i++) {
      if (i % 2 == 0 || i == points.length - 1) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].dx - textPainter.width / 2, size.height + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
