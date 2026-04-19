import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProService {
  static const String _isProKey = 'is_pro';
  static const String productId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> isPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isProKey) ?? false;
  }

  Future<void> setPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProKey, value);
  }

  void initPurchaseListener() {
    _subscription = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != productId) continue;

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await setPro(true);
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    });
  }

  Future<void> buyPro() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Google Play billing is not available on this device.');
    }

    final response = await _iap.queryProductDetails({productId});

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    if (response.productDetails.isEmpty) {
      throw Exception('Product "$productId" not found in Google Play.');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      final message = e.toString().toLowerCase();

      if (message.contains('already') && message.contains('own')) {
        await restore();
        return;
      }

      rethrow;
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> checkPastPurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}