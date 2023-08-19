import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService extends GetxService {
  // properties
  final String subscriptionEntitlement;
  final String apiKey;
  final bool debugLogsEnabled;

  // properties
  List<Package> items = [];
  bool isAvailable = false;

  // Constructor
  RevenueCatService({
    required this.subscriptionEntitlement,
    required this.apiKey,
    this.debugLogsEnabled = true,
  });

  Future<RevenueCatService> init() async {
    // check if device has billing
    isAvailable = await Purchases.canMakePayments();

    if (isAvailable) {
      // enable debug Logs
      Purchases.setDebugLogsEnabled(debugLogsEnabled);

      // set up the purchases
      await Purchases.setup(apiKey);

      // fetch products
      items.addAll(await fetchProducts());
    }

    return this;
  }

  // get current offer with packages products
  static Future<List<Package>> fetchProducts() async {
    // load offers
    Offerings offerings = await Purchases.getOfferings();

    // if not null
    if (offerings.current != null &&
        offerings.current!.availablePackages.isNotEmpty) {
      // return default offer
      return offerings.current!.availablePackages;
      // return offerings.all;
    } else {
      return [];
    }
  }

  //loop on product to get product
  Package? getProduct(String productId) {
    return items.firstWhereOrNull(
        (product) => product.storeProduct.identifier == productId);
  }

  String getProductPrice(String productId) {
    //loop on product to get product price
    Package? product = getProduct(productId);
    // return price
    if (product != null) return product.storeProduct.priceString;

    // return default value
    return '00.0';
  }

  // make a product Purchase
  Future<CustomerInfo> makePurchase(Package package) async {
    try {
      // attempt to buy a product
      return await Purchases.purchasePackage(package);
    } on PlatformException catch (exception) {
      var errorCode = PurchasesErrorHelper.getErrorCode(exception);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw 'purchaseCancelledError';
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        throw 'purchaseNotAllowedError';
      } else if (errorCode == PurchasesErrorCode.storeProblemError) {
        throw 'storeProblemError';
      } else if (errorCode == PurchasesErrorCode.networkError) {
        throw 'networkError';
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        throw 'productAlreadyPurchasedError';
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        throw 'paymentPendingError';
      } else if (errorCode == PurchasesErrorCode.purchaseInvalidError) {
        throw 'purchaseInvalidError';
      } else {
        throw 'Something went wrong';
      }
    }
  }

  // condition for check check if entitlement of subscription is active
  CustomerInfo? isSubscriptionIsExistAndActive(CustomerInfo? CustomerInfo) {
    if (CustomerInfo != null &&
        CustomerInfo.entitlements.all[subscriptionEntitlement] != null &&
        CustomerInfo.entitlements.all[subscriptionEntitlement]!.isActive) {
      return CustomerInfo;
    } else {
      return null;
    }
  }

  // Restore a Subscription
  Future<CustomerInfo?> restoreSubscription() async {
    // get restore transactions
    CustomerInfo restoredInfo = await Purchases.restorePurchases();

    // check if user still has a entitlement that related with subscription
    return isSubscriptionIsExistAndActive(restoredInfo);
  }

  // check current subscription Entitlements stats
  Future<bool> isSubscribed() async {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    return isSubscriptionIsExistAndActive(customerInfo) != null;
  }
}
