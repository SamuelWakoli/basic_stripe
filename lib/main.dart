import 'package:basic_stripe/auth_gate.dart';
import 'package:basic_stripe/screens/home_screen.dart';
import 'package:basic_stripe/screens/payment_cancelled_screen.dart';
import 'package:basic_stripe/screens/payments_screen.dart';
import 'package:basic_stripe/screens/products_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // DO NOT REMOVE!!!

import 'firebase_options.dart';

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// The app uses Email and GoogleProvider to sign in.
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(
        clientId:
            "875225395768-25sts3d8iv4k0n18h6in13v882176isp.apps.googleusercontent.com"),
  ]);

  initStripe();

  runApp(const MyApp());
}

Future<void> initStripe() async {
  Stripe.publishableKey =
      "pk_test_51Pq5rbRp8OTsf6OZlzPbNBD0jge4N5mQF14VKYOuLPUonPl3cunVqJCp4WA9uoTwVKmKfXQ2MsVYUONiHgHiJjrR00HX4HIqtt";
  await Stripe.instance.applySettings();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const AuthGate(), routes: {
      '/': (context) => const HomeScreen(),
      '/products': (context) => const ProductsScreen(),
      '/paymentCancelled': (context) => const PaymentCancelledScreen(),
      '/payments': (context) => const PaymentsScreen()
    });
  }
}
