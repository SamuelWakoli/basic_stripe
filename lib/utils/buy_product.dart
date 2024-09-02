import 'package:basic_stripe/utils/create_checkout_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> buyProduct({
  required BuildContext context,
  required String productId,
  required String productName,
  required double unitAmount,
  required String priceInDollars,
  required bool isRecurring,
  required int quantity,
  required String? stripeCustomerId,
}) async {
  String userEmail = FirebaseAuth.instance.currentUser!.email!;

  // Function to initiate the purchase
  void initiatePurchase() => createCheckoutSession(
        context: context,
        productId: productId,
        customerId: stripeCustomerId,
        email: userEmail,
        quantity: quantity,
      );

  if (isRecurring) {
    // Handle recurring purchases directly
    initiatePurchase();
  } else {
    // Handle one-time purchases with quantity adjustment
    showDialog(
      context: context,
      builder: (BuildContext ctx1) {
        int selectedQuantity = 1;
        bool showCustomQuantityField = false;

        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setState) {
            String totalAmount =
                (unitAmount / 100 * selectedQuantity).toStringAsFixed(2);
            return AlertDialog(
              title: Text(
                "Select Quantity",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Product:"),
                          const SizedBox(height: 4),
                          Text(
                            productName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceInDollars,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Choose a quantity:",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [1, 20, 50, 100, 200, "Custom"].map((qty) {
                      bool isSelected = qty == selectedQuantity ||
                          (qty == "Custom" && showCustomQuantityField);

                      return ChoiceChip(
                        label: Text(
                          qty.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (qty != "Custom") {
                              selectedQuantity = qty as int;
                              showCustomQuantityField = false;
                            } else {
                              showCustomQuantityField = true;
                              selectedQuantity = 1; // Default value for custom
                            }
                          });
                        },
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  ),
                  if (showCustomQuantityField)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            selectedQuantity = int.tryParse(value) ?? 1;
                          });
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: "Enter custom quantity",
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Total Amount: \$$totalAmount",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx1).pop(); // Dismiss the dialog
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    quantity = selectedQuantity;
                    initiatePurchase();
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text("Make Payment"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
