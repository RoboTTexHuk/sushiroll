import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'main.dart' show ChubbyTokenInitPage;

class CustomATTDialogScreen extends StatefulWidget {
  const CustomATTDialogScreen({Key? key}) : super(key: key);

  @override
  State<CustomATTDialogScreen> createState() => _CustomATTDialogScreenState();
}

class _CustomATTDialogScreenState extends State<CustomATTDialogScreen> {
  bool _showATTDialog = true;

  Future<void> _requestATT() async {
    await AppTrackingTransparency.requestTrackingAuthorization();
    setState(() {
      _showATTDialog = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChubbyTokenInitPage()),
    );
    // Optionally, handle the returned status here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: _showATTDialog
            ? _buildCustomDialog(context)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCustomDialog(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: Colors.blueAccent),
          const SizedBox(height: 18),
          const Text(
            'Allow Tracking?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Text(
            "We use your device's advertising identifier (IDFA) to show you more relevant ads and to improve your experience. Your data will not be shared with third parties without your consent. You can change your choice at any time in your device settings.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              child: const Text('Continue'),
              onPressed: _requestATT,
              padding: const EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}