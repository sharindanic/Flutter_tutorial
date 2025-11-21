/*

THIS CUBIT IS RESPONSIBLE FOR FETCHING & PURCHASING OFFERINGS FROM REVCAT

*/

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/revenuecat_service.dart';
import 'offerings_states.dart';

class OfferingsCubit extends Cubit<OfferingsState> {
  OfferingsCubit() : super(OfferingsInitial());

  // cache the loaded packages
  List<Package> _packages = [];

  // LOAD OFFERINGS
  Future<void> loadOfferings() async {
    emit(OfferingsLoading());

    try {
      Offerings? offerings = await RevenuecatService.fetchOfferings();

      // offerings are available
      if (offerings != null && offerings.current != null) {
        _packages = [];

        // add monthly package if available
        if (offerings.current!.monthly != null) {
          _packages.add(offerings.current!.monthly!);
        }

        // add yearly package if available
        if (offerings.current!.annual != null) {
          _packages.add(offerings.current!.annual!);
        }

        emit(OfferingsLoaded(_packages));
      }

      // no offerings available
      else {
        _packages = [];
        emit(OfferingsLoaded(_packages));
      }
    } catch (e) {
      print("Error fetching offerings: $e");
      emit(OfferingsError(e.toString()));
    }
  }

  // PURCHASE PACKAGE
  Future<void> purchasePackage(Package package, Function onSuccess) async {
    emit(PurchaseLoading());
    try {
      CustomerInfo? customerInfo =
          await RevenuecatService.purchasePackage(package);

      // successful purchase
      if (customerInfo != null &&
          customerInfo.entitlements.active.containsKey('pro')) {
        // after purchase, call onSuccess to let app know user successfully purchased.
        onSuccess();
      } else {
        // user cancelled purchase flow
        // revert to last kown offerings
        emit(OfferingsLoaded(_packages));
      }
    } on PlatformException catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError.name) {
        // user cancelled purchase flow
        // revert to last kown offerings
        emit(OfferingsLoaded(_packages));
      } else {
        print("Error purchasing package: $e");
        emit(PurchaseError(e.toString()));
      }
    } catch (e) {
      print("Error purchasing package: $e");
      emit(PurchaseError(e.toString()));
    }
  }
}
