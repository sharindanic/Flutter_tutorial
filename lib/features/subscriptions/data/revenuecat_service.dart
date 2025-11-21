import 'package:purchases_flutter/purchases_flutter.dart';

class RevenuecatService {
  // CONFIGURE REV CAT
  static Future<void> configureRevenueCat(String apiKey) async {
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      print("RevenueCat configured successfully");
    } catch (e) {
      print("Error configuring RevenueCat$e");
    }
  }

  // FETCH OFFERINGS
  static Future<Offerings?> fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      print("Offerings fetched successfully");
      return offerings;
    } catch (e) {
      print("Error fetching offerings: $e");
      return null;
    }
  }

  // PURCHASE A PACKAGE
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      print("Package purchases successfully");
      return customerInfo;
    } catch (e) {
      print("Error purchasing package: $e");
      return null;
    }
  }

  // IS PRO USER?
  static Future<bool> isProUser() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // customerInfo.entitlements.active -> returns a map of active entitlements,
      // where the keys are the entitlement ids we set up in revcat (e.g. pro).
      bool isPro = customerInfo.entitlements.active.containsKey('pro');
      print("isProUser: $isPro");
      return isPro;
    } catch (e) {
      print("Error checking pro status: $e");
      return false;
    }
  }
}
