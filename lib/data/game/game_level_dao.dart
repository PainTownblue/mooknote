import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../../models/data_models.dart';

/// 游戏关卡记录数据访问对象
class GameLevelDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<T> _wrap<T>(String op, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('[GameLevelDao] $op error: $e');
      rethrow;
    }
  }

  /// 获取某游戏的全部关卡（按关卡号升序）
  Future<List<GameLevel>> getLevelsByGameId(String gameId) => _wrap('getLevelsByGameId', () async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'game_levels',
      where: 'game_id = ? AND is_deleted = 0',
      whereArgs: [gameId],
      orderBy: 'level_no ASC',
    );
    return maps.map((m) => GameLevel.fromJson(m)).toList();
  });

  Future<GameLevel?> getLevelById(String id) => _wrap('getLevelById', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('game_levels', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return GameLevel.fromJson(maps.first);
  });

  /// 全部游戏的关卡（备份/导出用）
  Future<List<GameLevel>> getAllLevels() => _wrap('getAllLevels', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('game_levels', where: 'is_deleted = 0', orderBy: 'level_no ASC');
    return maps.map((m) => GameLevel.fromJson(m)).toList();
  });

  Future<int> insertLevel(GameLevel e) => _wrap('insertLevel', () async {
    final db = await _dbHelper.database;
    return await db.insert('game_levels', e.toJson());
  });

  Future<int> updateLevel(GameLevel e) => _wrap('updateLevel', () async {
    final db = await _dbHelper.database;
    return await db.update('game_levels', e.toJson(), where: 'id = ?', whereArgs: [e.id]);
  });

  // 子组行无独立墓碑/回收站，直接硬删；调用方负责删图片并 touch 父行 updated_at，
  // 由父行整组推送把删除传播到其他设备（软删会被同步/备份裸查带出，永久残留）
  Future<int> deleteLevel(String id) => _wrap('deleteLevel', () async {
    final db = await _dbHelper.database;
    return await db.delete('game_levels', where: 'id = ?', whereArgs: [id]);
  });
}
