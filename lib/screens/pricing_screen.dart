import 'package:basic_stripe/utils/buy_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DocumentSnapshot> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    QuerySnapshot productSnapshot = await FirebaseFirestore.instance
        .collection("products")
        .where("active", isEqualTo: true)
        .get();

    setState(() {
      products = productSnapshot.docs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Pricing Plans"),
        ),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Pricing Plans"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "One-Time"),
            Tab(text: "Recurring"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PricingTab(interval: 'one_time', products: products),
          PricingTab(interval: 'recurring', products: products),
        ],
      ),
    );
  }
}

class PricingTab extends StatefulWidget {
  final String interval;
  final List<DocumentSnapshot> products;

  const PricingTab({super.key, required this.interval, required this.products});

  @override
  _PricingTabState createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab>
    with AutomaticKeepAliveClientMixin<PricingTab> {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call this method in build

    if (widget.products.isEmpty) {
      return Center(
        child: Text(
          "No pricing plans available at the moment.",
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: widget.products.map((product) {
            return ProductCard(
              product: product,
              interval: widget.interval,
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ProductCard extends StatefulWidget {
  final DocumentSnapshot product;
  final String interval;

  const ProductCard({
    super.key,
    required this.product,
    required this.interval,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 1;
  String userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? stripeCustomerId;
  List<DocumentSnapshot> prices = [];
  bool isLoading = true;

  Future<void> getStripeCustomerId() async {
    DocumentReference customerDocRef = FirebaseFirestore.instance
        .collection("customers")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    DocumentSnapshot data = await customerDocRef.get();
    if (data.exists) {
      stripeCustomerId = data['stripeId'];
    }
  }

  Future<void> _fetchPrices() async {
    QuerySnapshot priceSnapshot = await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.product.id)
        .collection("prices")
        .where("active", isEqualTo: true)
        .where("type", isEqualTo: widget.interval)
        .get();

    setState(() {
      prices = priceSnapshot.docs;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getStripeCustomerId();
    _fetchPrices();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox();
    }

    if (prices.isEmpty) {
      return const SizedBox();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(),
              Text(
                "${widget.product['name']}",
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.product['description']}",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: prices.map((priceItem) {
                  String interval = priceItem['interval'] == null
                      ? ""
                      : "per ${priceItem['interval']}";

                  dynamic unitAmount = priceItem['unit_amount'];
                  String priceInDollars =
                      "\$${(unitAmount / 100).toStringAsFixed(2)} $interval";

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Divider(),
                        ),
                        Text(
                          priceInDollars,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            buyProduct(
                              context: context,
                              productId: widget.product.id,
                              productName: "${widget.product['name']}",
                              unitAmount: unitAmount,
                              priceInDollars: priceInDollars,
                              isRecurring: widget.interval == 'recurring',
                              quantity: quantity,
                              stripeCustomerId: stripeCustomerId,
                            );
                          },
                          child: Text(widget.interval == 'one_time'
                              ? "Buy"
                              : "Subscribe"),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
