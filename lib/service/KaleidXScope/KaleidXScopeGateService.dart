import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';

import '../../api/ApiUrls.dart';
import '../../entity/KaleidXScope/KaleidXScopeGate.dart';
import '../../utils/ApiClient.dart';

/// New gates use the existing server contract instead of one service per color.
class KaleidXScopeGateService {
  Future<List<KaleidXScopeGate>> fetchGates() async {
    final response =
        await ApiClient.get(Uri.parse('${ApiUrls.KaleidXScopeBaseUrl}/gates'));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 ||
        body['success'] != true ||
        body['data'] is! List) {
      throw StateError(appL10n.svcCouldNotLoadTheGateListRight);
    }
    return (body['data'] as List)
        .map((item) =>
            KaleidXScopeGate.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<KaleidXScopeGate> fetchGate(String color) async {
    final response = await ApiClient.get(Uri.parse(
        '${ApiUrls.KaleidXScopeBaseUrl}/gates/${Uri.encodeComponent(color)}'));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 ||
        body['success'] != true ||
        body['data'] is! Map) {
      throw StateError(appL10n.svcCouldNotLoadTheGuideRightNow);
    }
    final gate = KaleidXScopeGate.fromJson(
        Map<String, dynamic>.from(body['data'] as Map));
    if (gate.color != color) throw StateError(appL10n.svcTheGuideDataDoesNotMatch);
    return gate;
  }
}
