import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:gnosis_chat/features/subscription/domain/plan_entity.dart';

class RevenueCatService {
  static bool _isConfigured = false;

  /// Configure RevenueCat SDK on mobile devices. No-op on Web.
  static Future<void> init({String? userId}) async {
    if (kIsWeb) return;

    try {
      final apiKey = Platform.isIOS
          ? (dotenv.env['REVENUECAT_APPLE_KEY'] ?? const String.fromEnvironment('REVENUECAT_APPLE_KEY'))
          : (dotenv.env['REVENUECAT_GOOGLE_KEY'] ?? const String.fromEnvironment('REVENUECAT_GOOGLE_KEY'));

      if (apiKey.isEmpty || apiKey.startsWith('goog_placeholder')) {
        debugPrint('RevenueCat: No valid API key for ${Platform.operatingSystem}');
        return;
      }

      final configuration = PurchasesConfiguration(apiKey);
      if (userId != null && userId.isNotEmpty) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);
      _isConfigured = true;
      debugPrint('RevenueCat configured successfully for user: $userId');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  /// Update user ID upon login
  static Future<void> logIn(String userId) async {
    if (kIsWeb || !_isConfigured) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Log out upon sign out
  static Future<void> logOut() async {
    if (kIsWeb || !_isConfigured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
  }

  /// Purchase subscription on iOS or Android
  static Future<CustomerInfo?> purchasePlan(PlanType plan) async {
    if (kIsWeb) {
      throw UnsupportedError('RevenueCat is only supported on mobile platforms.');
    }

    if (!_isConfigured) {
      await init();
    }

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        throw Exception('Nenhuma oferta disponível no momento. Tente novamente mais tarde.');
      }

      Package? targetPackage;

      if (plan == PlanType.premium) {
        targetPackage = currentOffering.getPackage('premium') ??
            currentOffering.availablePackages.firstWhere(
              (p) => p.identifier == 'premium' || p.storeProduct.identifier == 'gnosis_premium_monthly',
              orElse: () => currentOffering.availablePackages.first,
            );
      } else {
        targetPackage = currentOffering.monthly ??
            currentOffering.getPackage('basic') ??
            currentOffering.availablePackages.firstWhere(
              (p) => p.identifier == '\$rc_monthly' || p.storeProduct.identifier == 'gnosis_basic_monthly',
              orElse: () => currentOffering.availablePackages.first,
            );
      }

      final result = await Purchases.purchase(
        PurchaseParams.package(targetPackage),
      );
      return result.customerInfo;
    } catch (e) {
      debugPrint('RevenueCat purchase error: $e');
      rethrow;
    }
  }

  /// Restore purchases (e.g. user reinstalled app or changed device)
  static Future<CustomerInfo?> restorePurchases() async {
    if (kIsWeb || !_isConfigured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('RevenueCat restore error: $e');
      rethrow;
    }
  }
}
