import 'package:basic_stripe/utils/create_checkout_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductListItem extends StatefulWidget {
  final DocumentSnapshot product;

  const ProductListItem({super.key, required this.product});

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  bool showMore = false;
  String userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? stripeCustomerId;

  Future<void> getStripeCustomerId() async {
    DocumentReference customerDocRef = FirebaseFirestore.instance
        .collection("customers")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    customerDocRef.get().then((data) {
      if (data.exists) {
        stripeCustomerId = data['stripeId'];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getStripeCustomerId();
  }

  @override
  Widget build(BuildContext context) {
    DocumentSnapshot product = widget.product;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primaryContainer),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product ID: ${product.id}"),
              const SizedBox(height: 8),
              Text(
                "${product['name']}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                "Description: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("${product['description']}"),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("products")
                          .doc(product.id)
                          .collection("prices")
                          .where("active", isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  )));
                        }

                        if (snapshot.data == null) {
                          return const Text("No Data");
                        }

                        return Column(
                          children: snapshot.data!.docs.map((priceItem) {
                            int unitAmount = priceItem['unit_amount'];
                            String interval = priceItem['interval'] == null
                                ? ""
                                : "per ${priceItem['interval']}";

                            String type = priceItem['type'] == "one_time"
                                ? "One Time Payment"
                                : priceItem['type'] == "recurring"
                                    ? "Recurring"
                                    : "";

                            String priceInDollars =
                                "\$${unitAmount ~/ 100} $interval";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  priceInDollars,
                                  style:
                                      Theme.of(context).textTheme.headlineLarge,
                                ),
                                Text(
                                  type,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: OutlinedButton(
                                      onPressed: () {
                                        // createPaymentLink(
                                        //     context: context,
                                        //     productId: product.id,
                                        //     customerId: stripeCustomerId,
                                        //     email: userEmail,
                                        //     quantity: 1);

                                        createCheckoutSession(
                                            context: context,
                                            productId: product.id,
                                            customerId: stripeCustomerId,
                                            email: userEmail,
                                            quantity: 1);
                                      },
                                      child: Text(type == "Recurring"
                                          ? "Subscribe"
                                          : "Buy")),
                                )
                              ],
                            );
                          }).toList(),
                        );
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
