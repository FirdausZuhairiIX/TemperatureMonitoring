import 'package:flutter/material.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double currentTemperature = 36.5;
  String userName = "Alex";
  DateTime selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _temperatureAnimation;

  // Sample temperature history data
  final List<Map<String, dynamic>> tempHistory = [
    {'value': 37.2, 'timestamp': DateTime.now().subtract(Duration(minutes: 5))},
    {'value': 37.8, 'timestamp': DateTime.now().subtract(Duration(hours: 1))},
    {'value': 38.1, 'timestamp': DateTime.now().subtract(Duration(days: 1))},
  ];

  void simulateTemperature() {
    double newTemp = 36 + Random().nextDouble() * 2.5;

    // Animate the temperature change
    _animationController.reset();
    _temperatureAnimation = Tween<double>(
      begin: currentTemperature,
      end: newTemp,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    setState(() {
      currentTemperature = newTemp;
    });
  }

  void updateUserName(String newName) {
    setState(() {
      userName = newName;
    });
  }

  List<Map<String, dynamic>> getFilteredHistory() {
    return tempHistory
        .where((entry) =>
    entry['timestamp'].year == selectedDate.year &&
        entry['timestamp'].month == selectedDate.month &&
        entry['timestamp'].day == selectedDate.day)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    // First, initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Then, initialize the animation with the current temperature
    _temperatureAnimation = Tween<double>(
      begin: currentTemperature,
      end: currentTemperature,
    ).animate(_animationController);

    _animationController.addListener(() {
      setState(() {});
    });

    // Call simulateTemperature after animations are properly set up
    Future.delayed(Duration.zero, () {
      simulateTemperature();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Determine the temperature status and color
    String tempStatus;
    Color tempColor;
    IconData tempIcon;

    double displayTemperature = _animationController.isAnimating
        ? _temperatureAnimation.value
        : currentTemperature;

    if (displayTemperature < 36.0) {
      tempStatus = "Low";
      tempColor = Colors.blue.shade700;
      tempIcon = Icons.ac_unit;
    } else if (displayTemperature >= 36.0 && displayTemperature <= 37.5) {
      tempStatus = "Normal";
      tempColor = Colors.green;
      tempIcon = Icons.check_circle;
    } else {
      tempStatus = "High";
      tempColor = Colors.red;
      tempIcon = Icons.warning_amber;
    }

    // Calculate temperature gauge position (between 35°C and 40°C)
    double gaugePosition = (displayTemperature - 35) / 5; // Normalized between 0 and 1
    gaugePosition = gaugePosition.clamp(0.0, 1.0); // Ensure it stays within bounds

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF66A6FF),
                Color(0xFF2A54D5),
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/pp1.jpg'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Health Monitor",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: "Dashboard",
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: "View History",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/history');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.edit,
                  title: "Edit Profile",
                  onTap: () async {
                    Navigator.pop(context);
                    String? newName = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController controller = TextEditingController();
                        controller.text = userName;

                        return AlertDialog(
                          title: Text("Edit Profile"),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: "Name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, controller.text);
                              },
                              child: Text("Save"),
                            ),
                          ],
                        );
                      },
                    );
                    if (newName != null && newName.isNotEmpty) {
                      updateUserName(newName);
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_add,
                  title: "Add User",
                  onTap: () {
                    Navigator.pop(context);
                    print("Adding user...");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.3)),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF66A6FF), Color(0xFF2A54D5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section with user info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/images/pp1.jpg'),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, $userName",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Let's check your temperature",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Date display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${_getDayOfWeek(DateTime.now())}, ${_formatDate(DateTime.now())}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),

              // Main temperature display card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    color: Colors.white,
                    child: Container(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Temperature half circle gauge
                          Container(
                            height: size.height * 0.25,
                            child: CustomPaint(
                              size: Size(size.width * 0.8, size.height * 0.25),
                              painter: TemperatureGaugePainter(
                                gaugePosition: gaugePosition,
                                arcColor: tempColor,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20),
                                    Icon(
                                      tempIcon,
                                      size: 32,
                                      color: tempColor,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      displayTemperature.toStringAsFixed(1) + " °C",
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: tempColor,
                                      ),
                                    ),
                                    Text(
                                      tempStatus,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: tempColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Scale indicators
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "35°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "36°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "37°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "38°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "39°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "40°",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Temperature status card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: tempColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    tempIcon,
                                    color: tempColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tempStatus + " Temperature",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: tempColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _getTemperatureAdvice(displayTemperature),
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

                          // Last check time
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Last updated: " + _formatTime(DateTime.now()),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Button row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: simulateTemperature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF2A54D5),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        icon: Icon(Icons.refresh),
                        label: Text("Refresh", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2A54D5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        icon: Icon(Icons.history),
                        label: Text("History", style: TextStyle(fontSize: 16)),
                      ),
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

  // Helper function to build drawer items
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to get day of week
  String _getDayOfWeek(DateTime date) {
    List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  // Helper function to format date
  String _formatDate(DateTime date) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // Helper function to format time
  String _formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // Helper function to get temperature advice
  String _getTemperatureAdvice(double temp) {
    if (temp < 36.0) {
      return "Your temperature is below normal range";
    } else if (temp >= 36.0 && temp <= 37.5) {
      return "Your temperature is within normal range";
    } else {
      return "Your temperature is above normal range";
    }
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

      // Only draw tick marks if it's a milestone (every 0.5°C)
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