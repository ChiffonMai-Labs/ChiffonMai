import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import 'ApiClient.dart';
import 'SecureCredentialStore.dart';

/// 水鱼账号是否开启了「对非网页查询的成绩使用掩码」（`/player/profile` 的 `mask`）。
///
/// 开启后，App 通过 OAuth 读到的水鱼成绩是打过码的，不能如实反映真实成绩，
/// 所以这时不允许用水鱼数据参与排行榜：带「参与排行榜」的对话框禁用勾选框并说明原因，
/// 刷新时也不会上传排行榜数据。落雪、AWMC 的数据不受影响。
class DivingFishMaskStatus extends ValueNotifier<bool> {
  DivingFishMaskStatus._() : super(false);

  static final DivingFishMaskStatus instance = DivingFishMaskStatus._();

  bool _loaded = false;
  Future<bool>? _refreshing;

  /// 读本地缓存（只读一次）。
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(CacheKeyConstant.probeDivingFishMask) ?? false;
    } catch (e) {
      debugPrint('[DivingFishMask] 读取缓存失败: $e');
    }
  }

  /// 从一次 `/player/profile` 响应里记下 `mask`；响应里没有这个字段时保持原值。
  Future<void> updateFromProfile(Map<String, dynamic> profile) async {
    final raw = profile['mask'];
    if (raw is! bool) return;
    _loaded = true;
    value = raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeyConstant.probeDivingFishMask, raw);
    } catch (e) {
      debugPrint('[DivingFishMask] 写入缓存失败: $e');
    }
  }

  /// 用已保存的水鱼登录凭证重新读一次 profile，返回最新状态。
  /// 没有登录凭证或请求失败时返回缓存值；并发调用合并成一次请求。
  Future<bool> refresh() => _refreshing ??= _refresh().whenComplete(() {
        _refreshing = null;
      });

  Future<bool> _refresh() async {
    await load();
    try {
      final jwt = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishToken);
      if (jwt == null || jwt.isEmpty) return value;
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.DivingFishProfileApi),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'jwt_token=$jwt',
        },
      );
      if (response.statusCode != 200) return value;
      final profile = json.decode(response.body);
      if (profile is Map<String, dynamic>) await updateFromProfile(profile);
    } catch (e) {
      debugPrint('[DivingFishMask] 刷新失败，沿用缓存: $e');
    }
    return value;
  }

  /// 退出水鱼账号时清掉。
  Future<void> clear() async {
    value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CacheKeyConstant.probeDivingFishMask);
    } catch (_) {}
  }
}
