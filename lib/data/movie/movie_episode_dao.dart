import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../../models/data_models.dart';

/// 影视分集记录数据访问对象
class MovieEpisodeDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<T> _wrap<T>(String op, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('[MovieEpisodeDao] $op error: $e');
      rethrow;
    }
  }

  /// 获取某影片的全部分集（按集号升序）
  Future<List<MovieEpisode>> getEpisodesByMovieId(String movieId) => _wrap('getEpisodesByMovieId', () async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'movie_episodes',
      where: 'movie_id = ? AND is_deleted = 0',
      whereArgs: [movieId],
      orderBy: 'episode_no ASC',
    );
    return maps.map((m) => MovieEpisode.fromJson(m)).toList();
  });

  Future<MovieEpisode?> getEpisodeById(String id) => _wrap('getEpisodeById', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('movie_episodes', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MovieEpisode.fromJson(maps.first);
  });

  /// 全部影片的分集（备份/导出用）
  Future<List<MovieEpisode>> getAllEpisodes() => _wrap('getAllEpisodes', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('movie_episodes', where: 'is_deleted = 0', orderBy: 'episode_no ASC');
    return maps.map((m) => MovieEpisode.fromJson(m)).toList();
  });

  Future<int> insertEpisode(MovieEpisode e) => _wrap('insertEpisode', () async {
    final db = await _dbHelper.database;
    return await db.insert('movie_episodes', e.toJson());
  });

  Future<int> updateEpisode(MovieEpisode e) => _wrap('updateEpisode', () async {
    final db = await _dbHelper.database;
    return await db.update('movie_episodes', e.toJson(), where: 'id = ?', whereArgs: [e.id]);
  });

  // 子组行无独立墓碑/回收站，直接硬删；调用方负责删图片并 touch 父行 updated_at，
  // 由父行整组推送把删除传播到其他设备（软删会被同步/备份裸查带出，永久残留）
  Future<int> deleteEpisode(String id) => _wrap('deleteEpisode', () async {
    final db = await _dbHelper.database;
    return await db.delete('movie_episodes', where: 'id = ?', whereArgs: [id]);
  });
}
