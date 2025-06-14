import 'package:flutter/material.dart';
import 'dart:math';

class HomeScreenUI {
  // Helper function to get day of week
  static String getDayOfWeek(DateTime date) {
    List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  // Helper function to format date
  static String formatDate(DateTime date) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // Helper function to get temperature advice
  static String getTemperatureAdvice(double temp) {
    if (temp < 35.0) {
      return "Your temperature is below normal range";
    } else if (temp >= 35.0 && temp <= 37.5) {
      return "Your temperature is within normal range";
    } else {
      return "Your temperature is above normal range";
    }
  }

  // Get temperature status and styling information
  static Map<String, dynamic> getTemperatureStatus(double temperature) {
    String tempStatus;
    Color tempColor;
    IconData tempIcon;

    if (temperature < 34.0) {
      tempStatus = "Low";
      tempColor = Colors.blue.shade700;
      tempIcon = Icons.ac_unit;
    } else if (temperature >= 34.0 && temperature <= 37.0) {
      tempStatus = "Normal";
      tempColor = Colors.green;
      tempIcon = Icons.check_circle;
    } else if (temperature > 37.0 && temperature <= 37.5) {
      tempStatus = "Mild";
      tempColor = Colors.orange;
      tempIcon = Icons.warning_amber;
    } else {
      tempStatus = "High";
      tempColor = Colors.red;
      tempIcon = Icons.warning_amber;
    }

    return {
      'status': tempStatus,
      'color': tempColor,
      'icon': tempIcon,
    };
  }

  // Dynamic background gradient based on temperature
  static List<Color> getBackgroundGradient(double temperature) {
    if (temperature < 34.0) {
      // Cold (blue)
      return [const Color(0xFF59C3FF), const Color(0xFF2A54D5)];
    } else if (temperature >= 34.0 && temperature <= 37.0) {
      // Normal (green)
      return [const Color(0xFF90F7EC), const Color(0xFF32CCBC)];
    } else if (temperature > 37.0 && temperature <= 37.5) {
      // Mild fever (orange/light red)
      return [const Color(0xFFFFE29F), const Color(0xFFFF6A6A)];
    } else {
      // High fever (red)
      return [const Color(0xFFFF5858), const Color(0xFFFF0000)];
    }
  }

  static Widget buildLoadingScreen(String toddlerName) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Loading $toddlerName's data...",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildErrorScreen({
    required BuildContext context,
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                "Error Loading Data",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text("Retry"),
              ),
              if (errorMessage.contains("logged in"))
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Go to Login"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildHeaderSection({
    required String userName,
    required String toddlerName,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Color(0xFF2A54D5)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $userName",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Let's check $toddlerName's temperature",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildDateDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "${getDayOfWeek(DateTime.now())}, ${formatDate(DateTime.now())}",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  static Widget buildToddlerInfoCard({
    required String toddlerName,
    required int toddlerAge,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF2A54D5).withOpacity(0.1),
                child: const Icon(
                  Icons.child_care,
                  size: 40,
                  color: Color(0xFF2A54D5),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toddlerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "$toddlerAge ${toddlerAge == 1 ? 'year' : 'years'} old",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Monitoring active",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTemperatureCard({
    required BuildContext context,
    required double displayTemperature,
    required double gaugePosition,
    required Map<String, dynamic> tempStatus,
    required String lastUpdateTime,
  }) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: size.height * 0.25,
                child: CustomPaint(
                  size: Size(size.width * 0.8, size.height * 0.25),
                  painter: TemperatureGaugePainter(
                    gaugePosition: gaugePosition,
                    arcColor: tempStatus['color'],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          tempStatus['icon'],
                          size: 32,
                          color: tempStatus['color'],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${displayTemperature.toStringAsFixed(1)} °C",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: tempStatus['color'],
                          ),
                        ),
                        Text(
                          tempStatus['status'],
                          style: TextStyle(
                            fontSize: 18,
                            color: tempStatus['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("35°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("36°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("37°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("38°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("39°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("40°", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tempStatus['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tempStatus['icon'],
                        color: tempStatus['color'],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tempStatus['status']} Temperature",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tempStatus['color'],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getTemperatureAdvice(displayTemperature),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Last updated: $lastUpdateTime",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the half-circle temperature gauge
class TemperatureGaugePainter extends CustomPainter {
  final double gaugePosition; // 0.0 to 1.0
  final Color arcColor;

  TemperatureGaugePainter({
    required this.gaugePosition,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.9,
      size.height * 2.0,
    );

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi,
      pi,
      false,
      backgroundPaint,
    );

    // Filled arc based on temperature
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi,
      pi * gaugePosition,
      false,
      arcPaint,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      double angle = -pi + (pi / 10 * i);
      double x1 = size.width / 2 + cos(angle) * (size.width * 0.4);
      double y1 = size.height + sin(angle) * (size.width * 0.4);
      double x2 = size.width / 2 + cos(angle) * (size.width * 0.35);
      double y2 = size.height + sin(angle) * (size.width * 0.35);

      if (i % 2 == 0) {
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureGaugePainter oldDelegate) {
    return oldDelegate.gaugePosition != gaugePosition ||
        oldDelegate.arcColor != arcColor;
  }
}