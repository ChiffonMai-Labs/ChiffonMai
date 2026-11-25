import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';

import '../../api/ApiUrls.dart';
import '../../entity/KaleidXScope/KaleidXScopeGate.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppError.dart';

/// New gates use the existing server contract instead of one service per color.
class KaleidXScopeGateService {
  Future<List<KaleidXScopeGate>> fetchGates() async {
    final response =
        await ApiClient.get(Uri.parse('${ApiUrls.KaleidXScopeBaseUrl}/gates'));
    if (response.statusCode != 200) {
      throw ApiClient.parseError(
        response,
        stage: '读取万花筒列表',
        source: 'chiffonmai',
        fallbackCode: 'SRV-KALEID-LIST',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] is! List) {
      throw AppError(
        code: 'SRV-KALEID-LIST',
        userMessage: appL10n.svcCouldNotLoadTheGateListRight,
        stage: '读取万花筒列表',
        source: 'chiffonmai',
      );
    }
    return (body['data'] as List)
        .map((item) =>
            KaleidXScopeGate.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<KaleidXScopeGate> fetchGate(String color) async {
    final response = await ApiClient.get(Uri.parse(
        '${ApiUrls.KaleidXScopeBaseUrl}/gates/${Uri.encodeComponent(color)}'));
    if (response.statusCode != 200) {
      throw ApiClient.parseError(
        response,
        stage: '读取万花筒攻略',
        source: 'chiffonmai',
        fallbackCode: 'SRV-KALEID-DETAIL',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] is! Map) {
      throw AppError(
        code: 'SRV-KALEID-DETAIL',
        userMessage: appL10n.svcCouldNotLoadTheGuideRightNow,
        stage: '读取万花筒攻略',
        source: 'chiffonmai',
      );
    }
    final gate = KaleidXScopeGate.fromJson(
        Map<String, dynamic>.from(body['data'] as Map));
    if (gate.color != color) {
      throw AppError(
        code: 'DATA-KALEID-MISMATCH',
        userMessage: appL10n.svcTheGuideDataDoesNotMatch,
        stage: '校验万花筒攻略',
        source: 'chiffonmai',
      );
    }
    return gate;
  }
}
