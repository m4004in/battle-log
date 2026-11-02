import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tournament_record.dart';
import '../models/record_folder.dart';

class TournamentProvider extends ChangeNotifier {
  List<TournamentRecord> _records = [];
  static const String _storageKey = 'tournament_records';

  List<RecordFolder> _folders = [];
  static const String _folderKey = 'record_folders';

  List<TournamentRecord> get records => _records;
  List<RecordFolder> get folders => _folders;

  List<TournamentRecord> recordsInFolder(String folderId) =>
      _records.where((r) => r.folderId == folderId).toList();

  RecordFolder? folderById(String? id) {
    if (id == null) return null;
    for (final f in _folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  TournamentProvider() {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final folderStr = prefs.getString(_folderKey);
      if (folderStr != null) {
        final List<dynamic> fl = jsonDecode(folderStr);
        _folders = fl
            .map((j) => RecordFolder.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      }
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _records = jsonList.map((j) => TournamentRecord.fromJson(j)).toList();
        _sortRecords();
      }
      notifyListeners();
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

  Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _folderKey, jsonEncode(_folders.map((f) => f.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving folders: $e');
    }
  }

  Future<RecordFolder> addFolder(String name) async {
    final folder = RecordFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    _folders.add(folder);
    await _saveFolders();
    notifyListeners();
    return folder;
  }

  Future<void> renameFolder(String id, String name) async {
    final f = folderById(id);
    if (f == null) return;
    f.name = name.trim();
    await _saveFolders();
    notifyListeners();
  }

  /// 폴더만 삭제 (안에 있던 기록은 지워지지 않고 폴더 없음 상태로 돌아감)
  Future<void> deleteFolder(String id) async {
    _folders.removeWhere((f) => f.id == id);
    for (final r in _records) {
      if (r.folderId == id) r.folderId = null;
    }
    await _saveFolders();
    await _saveRecords();
    notifyListeners();
  }

  Future<void> setRecordFolder(String recordId, String? folderId) async {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index == -1) return;
    _records[index].folderId = folderId;
    await _saveRecords();
    notifyListeners();
  }
}
