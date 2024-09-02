import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> createPaymentLink({
  required BuildContext context,
  required String productId,
  required String email,
  required int quantity,
  String?
      customerId, // in case we don't have customer id, we can create new customer in cloud using the email
}) async {
  try {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('createPaymentLink');
    final response = await callable.call(<String, dynamic>{
      'productId': productId, // Pass the product ID
      'customerEmail': email, // Pass customer email
      'customerId': customerId, // Pass customer ID if available
      'quantity': quantity, // Pass the quantity
    });
    final paymentUrl = response.data['url'];

    // Open the payment link in a new tab
    if (paymentUrl != null) {
      final Uri url = Uri.parse(paymentUrl);

      if (!await launchUrl(url, webOnlyWindowName: '_self')) {
        throw Exception('Could not launch $url');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error creating payment link: $e');
    }
  }
}
