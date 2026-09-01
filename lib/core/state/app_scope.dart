import 'package:flutter/material.dart';

import '../network/movie_api_client.dart';
import 'app_settings.dart';
import 'app_stores.dart';

/// Down-the-tree access to the bootstrapped singletons: settings, stores and
/// the API client. Written once in `main.dart` above [MaterialApp]'s home.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required this.stores,
    required this.apiClient,
    required super.child,
  }) : super(notifier: settings);

  final AppStores stores;
  final MovieApiClient apiClient;

  /// The settings notifier this scope listens to.
  AppSettings get settings => notifier!;

  static AppScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above $context');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      stores != oldWidget.stores || apiClient != oldWidget.apiClient;
}
