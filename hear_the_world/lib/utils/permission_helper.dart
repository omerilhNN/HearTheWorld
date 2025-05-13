import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // In a real app, we would use permission_handler to request camera permissions
      // For this demo, we'll just check if the image picker can access the camera
      final ImagePicker picker = ImagePicker();
      final XFile? testImage = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1,
        maxHeight: 1,
        imageQuality: 1,
      );
      
      // If user cancelled, that's not an error, but we return false
      if (testImage == null) {
        return false;
      }
      
      // Clean up test image
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Camera permission error: $e');
      }
      
      // Show permission denied dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'This app needs camera permission to capture photos for analysis. '
              'Please enable camera permissions in your device settings.'
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
