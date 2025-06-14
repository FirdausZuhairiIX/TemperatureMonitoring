import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SideDrawerModel extends StatelessWidget {
  final String userName;
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const SideDrawerModel({
    super.key,
    required this.userName,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
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
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: Color(0xFF2A54D5)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Health Monitor",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.3)),
                  ],
                ),
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.dashboard,
                title: "Dashboard",
                isSelected: currentTabIndex == 0,
                onTap: () {
                  onTabChanged(0);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.warning,
                title: "Alerts",
                isSelected: currentTabIndex == 1,
                onTap: () {
                  onTabChanged(1);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.history,
                title: "View History",
                isSelected: currentTabIndex == 2,
                onTap: () {
                  onTabChanged(2);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.settings,
                title: "Settings",
                isSelected: currentTabIndex == 3,
                onTap: () {
                  onTabChanged(3);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.3)),
              _buildDrawerItem(
                context: context,
                icon: Icons.logout,
                title: "Logout",
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 16),
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
}