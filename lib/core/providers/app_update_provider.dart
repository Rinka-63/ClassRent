import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/supabase_tables.dart';
import '../supabase/supabase_client_provider.dart';

const currentAppVersionName = '0.1.0';
const currentAppBuildNumber = 3;
const defaultPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.ti24a4.sewakelas';

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.forceUpdate,
    required this.currentVersionName,
    required this.currentBuildNumber,
    required this.minimumBuildNumber,
    required this.latestVersionName,
    required this.storeUrl,
    required this.messageId,
    required this.messageEn,
  });

  final bool forceUpdate;
  final String currentVersionName;
  final int currentBuildNumber;
  final int minimumBuildNumber;
  final String latestVersionName;
  final String storeUrl;
  final String messageId;
  final String messageEn;

  bool get requiresUpdate =>
      forceUpdate &&
      minimumBuildNumber > 0 &&
      currentBuildNumber < minimumBuildNumber;

  factory AppUpdateStatus.open([
    int currentBuildNumber = currentAppBuildNumber,
    String currentVersionName = currentAppVersionName,
  ]) =>
      AppUpdateStatus(
        forceUpdate: false,
        currentVersionName: currentVersionName,
        currentBuildNumber: currentBuildNumber,
        minimumBuildNumber: 0,
        latestVersionName: currentVersionName,
        storeUrl: defaultPlayStoreUrl,
        messageId: 'Versi aplikasi ini masih bisa digunakan.',
        messageEn: 'This app version can still be used.',
      );

  factory AppUpdateStatus.fromJson(
    Map<String, dynamic> json, {
    int currentBuildNumber = currentAppBuildNumber,
    String currentVersionName = currentAppVersionName,
  }) {
    final minBuild = _asInt(json['min_build_number']);
    final latestVersion = json['latest_version_name'] as String?;
    final storeUrl = json['android_store_url'] as String?;
    final forceUpdate = json['force_update'] as bool? ?? false;
    final messageId = json['message_id'] as String?;
    final messageEn = json['message_en'] as String?;

    return AppUpdateStatus(
      forceUpdate: forceUpdate,
      currentVersionName: currentVersionName,
      currentBuildNumber: currentBuildNumber,
      minimumBuildNumber: minBuild,
      latestVersionName: latestVersion?.trim().isNotEmpty == true
          ? latestVersion!.trim()
          : currentVersionName,
      storeUrl: storeUrl?.trim().isNotEmpty == true
          ? storeUrl!.trim()
          : defaultPlayStoreUrl,
      messageId: messageId?.trim().isNotEmpty == true
          ? messageId!.trim()
          : 'Versi baru ClassRent tersedia. Perbarui aplikasi untuk melanjutkan.',
      messageEn: messageEn?.trim().isNotEmpty == true
          ? messageEn!.trim()
          : 'A new ClassRent version is available. Update the app to continue.',
    );
  }

  bool get hasOptionalUpdate =>
      !requiresUpdate &&
      !forceUpdate &&
      ((minimumBuildNumber > 0 && currentBuildNumber < minimumBuildNumber) ||
          (latestVersionName.trim().isNotEmpty &&
              latestVersionName != currentVersionName));
}

final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final currentBuild =
      int.tryParse(packageInfo.buildNumber) ?? currentAppBuildNumber;
  final currentVersion = packageInfo.version.isNotEmpty
      ? packageInfo.version
      : currentAppVersionName;
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return AppUpdateStatus.open(currentBuild, currentVersion);
  }
  try {
    final row = await client
        .from(SupabaseTables.systemSettings)
        .select('value')
        .eq('key', 'app_version')
        .maybeSingle();
    final value = row?['value'];
    if (value is Map<String, dynamic>) {
      return AppUpdateStatus.fromJson(
        value,
        currentBuildNumber: currentBuild,
        currentVersionName: currentVersion,
      );
    }
    if (value is Map) {
      return AppUpdateStatus.fromJson(
        Map<String, dynamic>.from(value),
        currentBuildNumber: currentBuild,
        currentVersionName: currentVersion,
      );
    }
    return AppUpdateStatus.open(currentBuild, currentVersion);
  } catch (_) {
    return AppUpdateStatus.open(currentBuild, currentVersion);
  }
});

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
