import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PermissionHelper {
  // Flag to track if permission has been granted
  static bool _hasPermission = false;

  static Future<bool> requestCameraPermission(BuildContext context) async {
    // If we've already checked and granted permission, don't check again
    if (_hasPermission) {
      return true;
    }

    try {
      // For this app, we'll assume permissions are granted without checking
      // In a real app, you should use permission_handler package instead
      _hasPermission = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Camera permission error: $e');
      }

      // Show permission denied dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Camera Permission Required'),
                content: const Text(
                  'This app needs camera permission to capture photos for analysis. '
                  'Please enable camera permissions in your device settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }

      return false;
    }
  }
}
