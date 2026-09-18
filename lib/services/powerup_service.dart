import 'storage_service.dart';

class PowerUpService {
  // balance: 2 bombas iniciales, resto por rewarded
  static Future<int> getBombs() async => StorageService().prefs.getInt('pu_bombs') ?? 2;
  static Future<int> getFifty() async => StorageService().prefs.getInt('pu_fifty') ?? 2;
  static Future<int> getHints() async => StorageService().prefs.getInt('pu_hints') ?? 2;

  static Future<void> addBomb(int n) async {
    final p = StorageService().prefs;
    await p.setInt('pu_bombs', (p.getInt('pu_bombs') ?? 2) + n);
  }
  static Future<void> addFifty(int n) async {
    final p = StorageService().prefs;
    await p.setInt('pu_fifty', (p.getInt('pu_fifty') ?? 2) + n);
  }
  static Future<void> addHint(int n) async {
    final p = StorageService().prefs;
    await p.setInt('pu_hints', (p.getInt('pu_hints') ?? 2) + n);
  }

  static Future<bool> useBomb() async {
    final p = StorageService().prefs;
    final cur = p.getInt('pu_bombs') ?? 0;
    if (cur <= 0) return false;
    await p.setInt('pu_bombs', cur - 1);
    return true;
  }
  static Future<bool> useFifty() async {
    final p = StorageService().prefs;
    final cur = p.getInt('pu_fifty') ?? 0;
    if (cur <= 0) return false;
    await p.setInt('pu_fifty', cur - 1);
    return true;
  }
  static Future<bool> useHint() async {
    final p = StorageService().prefs;
    final cur = p.getInt('pu_hints') ?? 0;
    if (cur <= 0) return false;
    await p.setInt('pu_hints', cur - 1);
    return true;
  }
}
