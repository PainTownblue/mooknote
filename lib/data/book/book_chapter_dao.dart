import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../../models/data_models.dart';

/// 书籍分章记录数据访问对象
class BookChapterDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<T> _wrap<T>(String op, Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('[BookChapterDao] $op error: $e');
      rethrow;
    }
  }

  /// 获取某书籍的全部章节（按章号升序）
  Future<List<BookChapter>> getChaptersByBookId(String bookId) => _wrap('getChaptersByBookId', () async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'book_chapters',
      where: 'book_id = ? AND is_deleted = 0',
      whereArgs: [bookId],
      orderBy: 'chapter_no ASC',
    );
    return maps.map((m) => BookChapter.fromJson(m)).toList();
  });

  Future<BookChapter?> getChapterById(String id) => _wrap('getChapterById', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_chapters', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  });

  /// 全部书籍的章节（备份/导出用）
  Future<List<BookChapter>> getAllChapters() => _wrap('getAllChapters', () async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_chapters', where: 'is_deleted = 0', orderBy: 'chapter_no ASC');
    return maps.map((m) => BookChapter.fromJson(m)).toList();
  });

  Future<int> insertChapter(BookChapter c) => _wrap('insertChapter', () async {
    final db = await _dbHelper.database;
    return await db.insert('book_chapters', c.toJson());
  });

  Future<int> updateChapter(BookChapter c) => _wrap('updateChapter', () async {
    final db = await _dbHelper.database;
    return await db.update('book_chapters', c.toJson(), where: 'id = ?', whereArgs: [c.id]);
  });

  // 子组行无独立墓碑/回收站，直接硬删；调用方负责删图片并 touch 父行 updated_at，
  // 由父行整组推送把删除传播到其他设备（软删会被同步/备份裸查带出，永久残留）
  Future<int> deleteChapter(String id) => _wrap('deleteChapter', () async {
    final db = await _dbHelper.database;
    return await db.delete('book_chapters', where: 'id = ?', whereArgs: [id]);
  });
}
