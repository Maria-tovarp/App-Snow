import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _seenOnboardingKey = 'seen_onboarding_v2';
  static final Map<String, Map<String, dynamic>> _homeSummaryCache = {};

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, true);
  }

  static String _homeSummaryKey(String userId) => 'home_summary_$userId';

  static Future<void> loadHomeSummary(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_homeSummaryKey(userId));
    if (raw == null) return;

    try {
      _homeSummaryCache[userId] =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      await prefs.remove(_homeSummaryKey(userId));
    }
  }

  static Map<String, dynamic>? homeSummary(String userId) {
    final cached = _homeSummaryCache[userId];
    return cached == null ? null : Map<String, dynamic>.from(cached);
  }

  static Future<void> saveHomeSummary(
    String userId,
    Map<String, dynamic> summary,
  ) async {
    _homeSummaryCache[userId] = Map<String, dynamic>.from(summary);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homeSummaryKey(userId), jsonEncode(summary));
  }
}
