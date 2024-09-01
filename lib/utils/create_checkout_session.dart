import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> createCheckoutSession({
  required BuildContext context,
  required String productId,
  required String email,
  required int quantity,
  String?
      customerId, // in case we don't have customer id, we can create new customer in cloud using the email
}) async {
  try {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('createCheckoutSessionViaHTTP');
        
    final response = await callable.call(<String, dynamic>{
      'productId': productId, // Pass the product ID
      'customerEmail': email, // Pass customer email
      'customerId': customerId, // Pass customer ID if available
      'quantity': quantity, // Pass the quantity
      'successUrl': "https://basic-stripe.web.app/payments",
      'cancelUrl': "https://basic-stripe.web.app/paymentCancelled",
    });

    final sessionUrl = response.data['url'];

    // Open the checkout session URL in a new tab
    if (sessionUrl != null) {
      final Uri url = Uri.parse(sessionUrl);

      if (!await launchUrl(url, webOnlyWindowName: '_blank')) {
        throw Exception('Could not launch $url');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error creating checkout session: $e');
    }
  }
}
