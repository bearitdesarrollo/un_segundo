import 'dart:convert';
import 'storage_service.dart';

class CreatorChallenge {
  String title;
  List<String> emojis; // 4..20
  String question; // texto
  List<String> options;
  int correctIndex;
  String creator;
  CreatorChallenge({required this.title, required this.emojis, required this.question, required this.options, required this.correctIndex, required this.creator});
  Map<String, dynamic> toJson() => {'t': title, 'e': emojis, 'q': question, 'o': options, 'c': correctIndex, 'cr': creator};
  factory CreatorChallenge.fromJson(Map<String, dynamic> j) => CreatorChallenge(title: j['t'], emojis: List<String>.from(j['e']), question: j['q'], options: List<String>.from(j['o']), correctIndex: j['c'], creator: j['cr'] ?? 'Anónimo');
}

class CreatorService {
  static const _key = 'creator_challenges';
  static Future<List<CreatorChallenge>> load() async {
    final raw = StorageService().prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CreatorChallenge.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
  static Future<void> add(CreatorChallenge c) async {
    final list = await load();
    list.insert(0, c);
    if (list.length > 50) list.removeLast();
    await StorageService().prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
  static Future<void> removeAt(int idx) async {
    final list = await load();
    if (idx >= 0 && idx < list.length) {
      list.removeAt(idx);
      await StorageService().prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
    }
  }
}
