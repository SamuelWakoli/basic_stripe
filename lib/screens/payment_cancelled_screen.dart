import 'package:flutter/material.dart';

class PaymentCancelledScreen extends StatefulWidget {
  const PaymentCancelledScreen({super.key});

  @override
  State<PaymentCancelledScreen> createState() => _PaymentCancelledScreenState();
}

class _PaymentCancelledScreenState extends State<PaymentCancelledScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (predicate) => true);
            },
            icon: const Icon(Icons.arrow_back)),
        title: const Text("Payment Cancelled"),
      ),
    );
  }
}
