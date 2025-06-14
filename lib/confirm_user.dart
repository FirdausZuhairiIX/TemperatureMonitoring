import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfirmUserPage extends StatefulWidget {
  final String loggedInUser; // Pass this from your login page

  const ConfirmUserPage({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  State<ConfirmUserPage> createState() => _ConfirmUserPageState();
}

class _ConfirmUserPageState extends State<ConfirmUserPage> {
  String status = 'Press the button to send your user to ESP8266';

  Future<void> sendUserToESP() async {
    final deviceIp = '192.168.36.218'; // Your ESP8266 IP
    final url = Uri.parse('http://$deviceIp/setuser?user=${Uri.encodeComponent(widget.loggedInUser)}');

    setState(() => status = "Sending...");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        setState(() => status = "User sent successfully: ${response.body}");
      } else {
        setState(() => status = "Failed: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm User')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Logged in as: ${widget.loggedInUser}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: sendUserToESP,
              child: const Text('Send to ESP8266'),
            ),
            const SizedBox(height: 30),
            Text(status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}