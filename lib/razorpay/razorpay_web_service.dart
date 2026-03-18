import 'package:flutter/foundation.dart';
import 'razorpay_web_stub.dart'
    if (dart.library.js) 'razorpay_web_real.dart' as loader;

class RazorpayWebService {
  /// Opens Razorpay checkout on Web platform.
  /// Does nothing on mobile as mobile uses razorpay_flutter plugin.
  static void openRazorpayWeb({
    required Map<String, dynamic> options,
    required Function(Map<String, dynamic>) onSuccess,
    required Function() onDismiss,
    required Function(String) onError,
  }) {
    if (kIsWeb) {
      loader.openRazorpayWebJS(
        options: options,
        onSuccess: onSuccess,
        onDismiss: onDismiss,
        onError: onError,
      );
    }
  }
}
