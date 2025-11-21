import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubits/offerings_cubit.dart';
import '../cubits/offerings_states.dart';
import '../cubits/subscription_cubit.dart';
import '../cubits/subscription_states.dart';

class OfferingsPage extends StatelessWidget {
  const OfferingsPage({super.key});

  // urls for privacy policy & Apple's EULA
  final String privacyPolicyUrl =
      "https://mitchkoko.github.io/my-landing-page/privacy-policy.html";
  final String eulaUrl =
      "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

  // helper method to launch URLS
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // helper method to handle purchase
  void _handlePurchase(BuildContext context, Package package) {
    // get cubits
    final offeringsCubit = context.read<OfferingsCubit>();
    final subscriptionCubit = context.read<SubscriptionCubit>();

    // initiate purchase
    offeringsCubit.purchasePackage(
      package,

      // after successful purchase, refresh subscription status
      () {
        subscriptionCubit.checkProStatus();

        // wait until subscription state shows user is pro, then close the page
        subscriptionCubit.stream
            .firstWhere(
                (subState) => subState is SubscriptionLoaded && subState.isPro)
            .then(
              (value) => Navigator.pop(context),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // cubits
    final offeringsCubit = context.read<OfferingsCubit>();

    // load offerings as soon as page is built
    offeringsCubit.loadOfferings();

    // color scheme theme
    final colorScheme = Theme.of(context).colorScheme;

    // UI
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // privacy policy
            TextButton(
              onPressed: () => _launchUrl(privacyPolicyUrl),
              child: const Text("Privacy Policy"),
            ),

            // apple eula
            TextButton(
              onPressed: () => _launchUrl(eulaUrl),
              child: const Text("Terms of Use"),
            ),
          ],
        ),
      ),
      body: BlocBuilder<OfferingsCubit, OfferingsState>(
        builder: (context, state) {
          // loading..
          if (state is OfferingsLoading || state is OfferingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          // error..
          if (state is OfferingsError || state is PurchaseError) {
            final errorMsg = state is OfferingsError
                ? state.message
                : (state as PurchaseError).message;

            return Center(
              child: Text("Error: $errorMsg"),
            );
          }

          // loaded!
          if (state is OfferingsLoaded) {
            // get available packages
            final packages = state.packages;

            // no packages available
            if (packages.isEmpty) {
              return const Center(
                child: Text("No offerings available.."),
              );
            }

            // package are available
            return Column(
              children: [
                const SizedBox(height: 25),

                // describe what pro users get
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Pro users unlock posting and commenting capabilities. Subscriptions will auto-renew unless cancelled in the App Store account settings.",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 25),

                // display the list of packages
                Expanded(
                  child: ListView.builder(
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      // get each individual package
                      final package = packages[index];

                      // get subscription duration
                      final subDuration = package!.identifier.contains("annual")
                          ? "year"
                          : "month";

                      // return Card UI
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // package title
                              Text(
                                package.storeProduct.title,
                                style: TextStyle(
                                  color: colorScheme.inversePrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),

                              const SizedBox(height: 5),

                              // package price
                              Text(
                                '${package.storeProduct.priceString}/$subDuration',
                                style: TextStyle(color: colorScheme.primary),
                              ),

                              const SizedBox(height: 10),

                              // button to subscribe!
                              MaterialButton(
                                onPressed: () {
                                  // let offerings cubit handle this
                                  _handlePurchase(context, package);
                                },
                                color: Colors.green,
                                child: const Text(
                                  "Subscribe Now",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          // default fallback
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
