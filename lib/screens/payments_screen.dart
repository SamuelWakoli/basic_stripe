import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  User currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('customers')
              .doc(currentUser.uid)
              .collection('payments')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("An Error Occured: ${snapshot.error}"),
              );
            }

            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No Payments Found"),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot payment = snapshot.data!.docs[index];

                Map<String, dynamic> metadata =
                    payment.get('metadata') as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment ID: ${payment.id}"),
                        Text("Amount: ${payment.get('amount')}"),
                        Text(
                            "Amount: ${(payment.get('amount') / 100).toStringAsFixed(2)}"),
                        const Text("Items: "),
                        Column(
                          children: payment.get('items').map((item) {
                            return Text(
                                "${item.get('description') + " " + item.get('quantity')}");
                          }).toList(),
                        ),
                        const Divider(),
                        const Text("Metadata:"),
                        Text(metadata.toString()),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
