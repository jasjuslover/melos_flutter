import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

enum Flavor { local, dev, staging, production }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  bool get isProduction => flavor == Flavor.production;

  String get appName => switch (flavor) {
    Flavor.local => 'Local App',
    Flavor.dev => 'Dev App',
    Flavor.staging => 'Staging App',
    Flavor.production => 'App',
  };

  String? get bannerLabel => switch (flavor) {
    Flavor.local => 'LOCAL',
    Flavor.dev => 'DEV',
    Flavor.staging => 'STAGING',
    Flavor.production => null,
  };

  factory AppConfig.fromEnvironment() => AppConfig.resolve(
    flavorName: const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
    apiUrl: const String.fromEnvironment('API_URL'),
    nativeFlavor: appFlavor,
    platform: defaultTargetPlatform,
  );

  @visibleForTesting
  factory AppConfig.resolve({
    required String flavorName,
    required String apiUrl,
    required String? nativeFlavor,
    required TargetPlatform platform,
  }) {
    final flavor = Flavor.values.asNameMap()[flavorName];
    if (flavor == null) {
      throw StateError(
        'FLAVOR $flavorName is not recognized. Options: local, dev, staging, production',
      );
    }

    if (nativeFlavor != null && nativeFlavor != flavorName) {
      throw StateError(
        "--flavor $nativeFlavor isn't match with FLAVOR=$flavorName. "
        "Use --dart-define-from-file=config/$nativeFlavor.json",
      );
    }

    if (apiUrl.isNotEmpty) {
      if (flavor != Flavor.dev &&
          flavor != Flavor.local &&
          !apiUrl.startsWith('https://')) {
        throw StateError('API_URL for $flavorName must in HTTPS: $apiUrl');
      }

      return AppConfig(flavor: flavor, apiBaseUrl: apiUrl);
    }

    if (flavor != Flavor.dev && flavor != Flavor.local) {
      throw StateError('API_URL is required for flavor $flavorName');
    }

    return AppConfig(
      flavor: flavor,
      apiBaseUrl: platform == TargetPlatform.android
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080',
    );
  }
}

String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8080'
      : 'http://localhost:8080';
}
