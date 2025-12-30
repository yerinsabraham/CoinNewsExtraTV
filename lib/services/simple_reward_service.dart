
/// Simple mock reward service to avoid compilation issues
class SimpleRewardService {
  int _balance = 100;

  Future<int> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _balance;
  }

  Future<int> claimReward(String source, int amount) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _balance += amount;
    return amount;
  }
}