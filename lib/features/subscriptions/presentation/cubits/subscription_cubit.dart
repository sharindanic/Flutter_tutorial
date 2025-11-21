/*

CHECKS IF THE USER IS PRO OR FREE

*/

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/revenuecat_service.dart';
import 'subscription_states.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(SubscriptionInitial());

  Future<void> checkProStatus() async {
    emit(SubscriptionLoading());
    try {
      final bool isPro = await RevenuecatService.isProUser();
      print("Subscription Cubit: Pro Status is: $isPro");
      emit(SubscriptionLoaded(isPro));
    } catch (e) {
      print("Error checking sub status: $e");
      emit(SubscriptionError(e.toString()));
    }
  }
}
