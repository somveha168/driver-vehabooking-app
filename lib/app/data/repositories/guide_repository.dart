import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/guide_video.dart';
import '../models/platform_info.dart';

class GuideRepository {
  GuideRepository(this._api);

  final ApiClient _api;

  Future<List<GuideVideo>> videos({String? module}) async {
    final res = await _api.getJson(
      '${AppConfig.guideApiUrl}/videos',
      query: {if (module != null && module.isNotEmpty) 'module': module},
    );

    final data = (res as Map)['data'] as List? ?? [];
    return data
        .map((item) => GuideVideo.fromJson(item as Map<String, dynamic>))
        .where((video) => video.title.isNotEmpty)
        .toList();
  }

  Future<PlatformInfo> platformInfo() async {
    final res = await _api.getJson(AppConfig.platformInfoApiUrl);
    final data = (res as Map)['data'] as Map? ?? {};

    return PlatformInfo.fromJson(Map<String, dynamic>.from(data));
  }
}
