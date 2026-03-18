import 'dart:js' as js;

void openRazorpayWebJS({
  required Map<String, dynamic> options,
  required Function(Map<String, dynamic>) onSuccess,
  required Function() onDismiss,
  required Function(String) onError,
}) {
  final optionsMap = Map<String, dynamic>.from(options);
  
  // Inject the JS interop functions for Razorpay callbacks
  optionsMap['handler'] = js.allowInterop((response) {
    onSuccess({
      'razorpay_payment_id': response['razorpay_payment_id'],
      'razorpay_order_id': response['razorpay_order_id'],
      'razorpay_signature': response['razorpay_signature'],
    });
  });
  
  optionsMap['modal'] = {
    'ondismiss': js.allowInterop(() {
      onDismiss();
    }),
    'onerror': js.allowInterop((err) {
      onError(err.toString());
    }),
  };

  // Call the native Razorpay JS library (index.html needs to have the script tag)
  try {
    var rzp = js.JsObject(js.context['Razorpay'], [js.JsObject.jsify(optionsMap)]);
    rzp.callMethod('open');
  } catch (e) {
    onError(e.toString());
  }
}
