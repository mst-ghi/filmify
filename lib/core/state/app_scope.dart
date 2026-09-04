import 'package:flutter/material.dart';

import '../network/movie_api_client.dart';
import '../update/update_service.dart';
import 'app_settings.dart';
import 'app_stores.dart';

/// Down-the-tree access to the bootstrapped singletons: settings, stores, the
/// API client and the update service. Written once in `main.dart` via
/// `MaterialApp.builder`, so every route — including pushed pages and dialogs
/// — sits below it.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required this.stores,
    required this.apiClient,
    required this.update,
    required super.child,
  }) : super(notifier: settings);

  final AppStores stores;
  final MovieApiClient apiClient;
  final UpdateService update;

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
      stores != oldWidget.stores ||
      apiClient != oldWidget.apiClient ||
      update != oldWidget.update;
}
