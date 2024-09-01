import 'package:basic_stripe/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';

Future<void> main() async {
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
    return const MaterialApp(
      home: AuthGate(),
    );
  }
}
