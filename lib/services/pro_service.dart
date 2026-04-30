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
    _subscription?.cancel();

    _subscription = _iap.purchaseStream.listen(
          (purchases) async {
        for (final purchase in purchases) {
          if (purchase.productID != productId) continue;

          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            await setPro(true);
          }

          if (purchase.status == PurchaseStatus.error) {
            // Ошибку не пробрасываем наружу, чтобы ревью не видело краш/сырой error.
          }

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      },
      onError: (_) {
        // Не даём ошибке стрима ломать приложение.
      },
    );
  }

  Future<void> buyPro() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Purchases are currently unavailable. Please try again later.');
    }

    final response = await _iap.queryProductDetails({productId});

    if (response.error != null) {
      throw Exception(
        response.error!.message.isEmpty
            ? 'Unable to load purchase information.'
            : response.error!.message,
      );
    }

    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      throw Exception('Purchase is currently unavailable. Please try again later.');
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

      throw Exception('Unable to start purchase. Please try again later.');
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      throw Exception('Unable to restore purchases. Please try again later.');
    }
  }

  Future<void> checkPastPurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    try {
      await _iap.restorePurchases();
    } catch (_) {
      // Молча игнорируем при запуске, чтобы не ломать приложение.
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}