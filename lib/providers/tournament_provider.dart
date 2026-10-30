import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament_record.dart';

class TournamentProvider extends ChangeNotifier {
  List<TournamentRecord> _records = [];
  static const String _storageKey = 'tournament_records';

  List<TournamentRecord> get records => _records;

  TournamentProvider() {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _records = jsonList.map((j) => TournamentRecord.fromJson(j)).toList();
        _sortRecords();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
    }
  }

  // 대회 날짜 최신순 정렬 (같은 날짜면 나중에 만든 기록이 위)
  void _sortRecords() {
    _records.sort((a, b) {
      final ad = DateTime(a.date.year, a.date.month, a.date.day);
      final bd = DateTime(b.date.year, b.date.month, b.date.day);
      final c = bd.compareTo(ad);
      if (c != 0) return c;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_records.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving records: $e');
    }
  }

  Future<void> addRecord(TournamentRecord record) async {
    _records.add(record);
    _sortRecords();
    await _saveRecords();
    notifyListeners();
  }

  Future<void> updateRecord(TournamentRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      _sortRecords();
      await _saveRecords();
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveRecords();
    notifyListeners();
  }
}
