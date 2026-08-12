import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'premium_service.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();
  static const productId = 'snow_premium_monthly';

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? product;
  bool storeAvailable = false;
  bool loading = false;
  String? errorMessage;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  String get price => product?.price ?? '\$15.000 COP/mes';

  Future<void> initialize() async {
    if (!isSupported) return;
    _subscription ??= InAppPurchase.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {
        errorMessage = 'No fue posible consultar la compra.';
        loading = false;
        notifyListeners();
      },
    );

    storeAvailable = await InAppPurchase.instance.isAvailable();
    if (!storeAvailable) {
      errorMessage = 'La tienda no está disponible en este dispositivo.';
      notifyListeners();
      return;
    }

    final response = await InAppPurchase.instance.queryProductDetails(
      const {productId},
    );
    if (response.error != null) {
      errorMessage = response.error!.message;
    } else if (response.productDetails.isEmpty) {
      errorMessage =
          'Configura el producto $productId en App Store Connect.';
    } else {
      product = response.productDetails.first;
      errorMessage = null;
    }
    notifyListeners();
  }

  Future<void> buy() async {
    final selectedProduct = product;
    if (selectedProduct == null || loading) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    final started = await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: selectedProduct),
    );
    if (!started) {
      loading = false;
      errorMessage = 'No se pudo iniciar el proceso de compra.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (!storeAvailable) await initialize();
    loading = true;
    errorMessage = null;
    notifyListeners();
    await InAppPurchase.instance.restorePurchases();
    loading = false;
    notifyListeners();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          loading = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await PremiumService.instance.activateStoreEntitlement();
          loading = false;
          errorMessage = null;
          break;
        case PurchaseStatus.error:
          loading = false;
          errorMessage = purchase.error?.message ?? 'La compra falló.';
          break;
        case PurchaseStatus.canceled:
          loading = false;
          errorMessage = null;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
    notifyListeners();
  }
}
