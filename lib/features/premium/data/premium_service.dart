import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumService extends ChangeNotifier {
  PremiumService._();

  static final PremiumService instance = PremiumService._();

  DateTime? _trialEndsAt;
  bool _trialUsed = false;
  bool _subscriptionActive = false;
  DateTime? _subscriptionEndsAt;

  String get _userKey =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

  bool get isPremium =>
      (_subscriptionActive &&
          (_subscriptionEndsAt == null ||
              _subscriptionEndsAt!.isAfter(DateTime.now()))) ||
      (_trialEndsAt != null && _trialEndsAt!.isAfter(DateTime.now()));

  bool get canStartTrial => !_trialUsed && !isPremium;
  bool get isSubscriptionActive =>
      _subscriptionActive &&
      (_subscriptionEndsAt == null ||
          _subscriptionEndsAt!.isAfter(DateTime.now()));
  bool get isTrialActive =>
      !isSubscriptionActive &&
      _trialEndsAt != null &&
      _trialEndsAt!.isAfter(DateTime.now());
  DateTime? get trialEndsAt => _trialEndsAt;
  DateTime? get subscriptionEndsAt => _subscriptionEndsAt;

  int get trialDaysRemaining {
    if (_trialEndsAt == null || !isPremium) return 0;
    final hours = _trialEndsAt!.difference(DateTime.now()).inHours;
    return (hours / 24).ceil().clamp(1, 7).toInt();
  }

  Future<void> initialize() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client
            .from('premium_subscriptions')
            .select('status, trial_ends_at, current_period_end')
            .eq('user_id', user.id)
            .maybeSingle();
        if (row != null) {
          _trialUsed = true;
          _trialEndsAt = DateTime.tryParse(
            row['trial_ends_at']?.toString() ?? '',
          );
          final status = row['status']?.toString();
          final periodEnd = DateTime.tryParse(
            row['current_period_end']?.toString() ?? '',
          );
          _subscriptionActive = status == 'active' &&
              (periodEnd == null || periodEnd.isAfter(DateTime.now()));
          _subscriptionEndsAt = periodEnd;
          await _saveLocalState();
          notifyListeners();
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        final prefix = 'premium_$_userKey';
        _subscriptionActive =
            prefs.getBool('${prefix}_subscription_active') ?? false;
        _subscriptionEndsAt = DateTime.tryParse(
          prefs.getString('${prefix}_subscription_ends_at') ?? '',
        );
        _trialUsed = prefs.getBool('${prefix}_trial_used') ?? false;
        _trialEndsAt = DateTime.tryParse(
          prefs.getString('${prefix}_trial_ends_at') ?? '',
        );
        await _saveLocalState();
        notifyListeners();
        return;
      } catch (_) {
        // Permite trabajar sin conexión usando el último estado conocido.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = 'premium_$_userKey';
    _trialUsed = prefs.getBool('${prefix}_trial_used') ?? false;
    _subscriptionActive =
        prefs.getBool('${prefix}_subscription_active') ?? false;
    _subscriptionEndsAt = DateTime.tryParse(
      prefs.getString('${prefix}_subscription_ends_at') ?? '',
    );
    final rawDate = prefs.getString('${prefix}_trial_ends_at');
    _trialEndsAt = rawDate == null ? null : DateTime.tryParse(rawDate);
    notifyListeners();
  }

  Future<void> startTrial() async {
    await initialize();
    if (!canStartTrial) return;

    _trialUsed = true;
    _trialEndsAt = DateTime.now().add(const Duration(days: 7));
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('premium_subscriptions').insert({
          'user_id': user.id,
          'plan': 'premium_monthly',
          'status': 'trialing',
          'trial_started_at': DateTime.now().toUtc().toIso8601String(),
          'trial_ends_at': _trialEndsAt!.toUtc().toIso8601String(),
        });
      } on PostgrestException catch (error) {
        if (error.code == '23505') {
          await initialize();
          return;
        }
        // Si la tabla aún no fue migrada o no hay conexión, conserva el estado
        // local y lo sincronizará en una próxima activación válida.
      } catch (_) {
        // Respaldo local para uso sin conexión.
      }
    }
    await _saveLocalState();
    notifyListeners();
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'premium_$_userKey';
    await prefs.setBool('${prefix}_trial_used', _trialUsed);
    await prefs.setBool(
      '${prefix}_subscription_active',
      _subscriptionActive,
    );
    if (_subscriptionEndsAt != null) {
      await prefs.setString(
        '${prefix}_subscription_ends_at',
        _subscriptionEndsAt!.toIso8601String(),
      );
    }
    if (_trialEndsAt != null) {
      await prefs.setString(
        '${prefix}_trial_ends_at',
        _trialEndsAt!.toIso8601String(),
      );
    }
  }

  Future<void> activateStoreEntitlement() async {
    _subscriptionActive = true;
    _subscriptionEndsAt = DateTime.now().add(const Duration(days: 31));
    await _saveLocalState();
    notifyListeners();
  }
}
