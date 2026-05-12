import 'package:dio/dio.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final data = await _db
          .from('app_version')
          .select('version, apk_url, release_notes')
          .eq('id', 1)
          .single();

      final latest = _parseVersion(data['version'] as String);
      if (_isNewer(latest, current)) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndInstall(
    String apkUrl, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/esuyo_update.apk';

    await Dio().download(
      apkUrl,
      path,
      onReceiveProgress: onProgress,
    );

    await OpenFile.open(path);
  }

  static List<int> _parseVersion(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();

  static bool _isNewer(List<int> latest, List<int> current) {
    for (int i = 0; i < 3; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
