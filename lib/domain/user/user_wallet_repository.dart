abstract class UserWalletRepository {
  Future<int> getCoins();
  Future<void> saveCoins(int coins);
  Future<void> addCoins(int amount);
  Future<bool> deductCoins(int amount);
}
