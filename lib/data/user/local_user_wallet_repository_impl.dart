import 'package:shared_preferences/shared_preferences.dart';
import 'package:playingkorean/domain/user/user_wallet_repository.dart';

class LocalUserWalletRepositoryImpl implements UserWalletRepository {
  static const String _keyCoins = 'user_coins_wallet';
  static const int _defaultInitialCoins = 30; // 초기 엽전 30냥 지급

  @override
  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyCoins)) {
      await prefs.setInt(_keyCoins, _defaultInitialCoins);
      return _defaultInitialCoins;
    }
    return prefs.getInt(_keyCoins) ?? _defaultInitialCoins;
  }

  @override
  Future<void> saveCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCoins, coins);
  }

  @override
  Future<void> addCoins(int amount) async {
    final current = await getCoins();
    await saveCoins(current + amount);
  }

  @override
  Future<bool> deductCoins(int amount) async {
    final current = await getCoins();
    if (current < amount) {
      return false;
    }
    await saveCoins(current - amount);
    return true;
  }
}
