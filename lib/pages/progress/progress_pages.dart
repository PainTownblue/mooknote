import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/data_models.dart';
import '../../providers/app_provider.dart';
import '../../utils/image_path_helper.dart';
import '../../utils/image_picker_helper.dart';
import '../../utils/slide_up_page_route.dart';
import '../../utils/toast_util.dart';
import '../../widgets/app_overlay.dart';
import '../../widgets/edit_sheets.dart';
import '../../widgets/fade_in_local_image.dart';
import '../../widgets/image_grid_editor.dart';
import '../../data/gallery/image_asset_dao.dart';
import '../../l10n/app_strings.dart';

/// 分集/章节/关卡三类进度记录的通用配置
class ProgressConfig<T> {
  /// 列表页标题，如「分集记录」
  final String listTitle;

  /// 序号名称，如「集号」
  final String seqLabel;

  /// 单项名称（含序号占位），如「第{n}集」
  final String itemNoun;

  /// 完成状态名称，如「已观看」
  final String doneLabel;

  /// 完成日期名称，如「观看日期」
  final String dateLabel;

  final Future<List<T>> Function(AppProvider p, String parentId) load;
  final Future<void> Function(AppProvider p, T item) add;
  final Future<void> Function(AppProvider p, List<T> items) addBatch;
  final Future<void> Function(AppProvider p, T item) update;
  final Future<void> Function(AppProvider p, String id) remove;

  final String Function(T) idOf;
  final String Function(T) parentOf;
  final int Function(T) seqOf;
  final String Function(T) titleOf;
  final bool Function(T) doneOf;
  final DateTime? Function(T) dateOf;
  final double? Function(T) ratingOf;
  final String Function(T) reviewOf;
  final List<String> Function(T) imagesOf;

  final T Function({
    required String id,
    required String parentId,
    required int seq,
    required String title,
    required bool done,
    required DateTime? date,
    required double? rating,
    required String review,
    required List<String> images,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) create;

  final T Function(
    T old, {
    int? seq,
    String? title,
    bool? done,
    DateTime? date,
    double? rating,
    String? review,
    List<String>? images,
    DateTime? updatedAt,
  }) edit;

  final Future<String> Function(String parentId, String itemId) imagesDir;

  const ProgressConfig({
    required this.listTitle,
    required this.seqLabel,
    required this.itemNoun,
    required this.doneLabel,
    required this.dateLabel,
    required this.load,
    required this.add,
    required this.addBatch,
    required this.update,
    required this.remove,
    required this.idOf,
    required this.parentOf,
    required this.seqOf,
    required this.titleOf,
    required this.doneOf,
    required this.dateOf,
    required this.ratingOf,
    required this.reviewOf,
    required this.imagesOf,
    required this.create,
    required this.edit,
    required this.imagesDir,
  });

  String itemName(int seq) => itemNoun.trf({'n': seq});

  static final ProgressConfig<MovieEpisode> movie = ProgressConfig<MovieEpisode>(
    listTitle: '分集记录',
    seqLabel: '集号',
    itemNoun: '第{n}集',
    doneLabel: '已观看',
    dateLabel: '观看日期',
    load: (p, id) => p.getMovieEpisodes(id),
    add: (p, e) => p.addMovieEpisode(e),
    addBatch: (p, list) => p.addMovieEpisodesBatch(list),
    update: (p, e) => p.updateMovieEpisode(e),
    remove: (p, id) => p.removeMovieEpisode(id),
    idOf: (e) => e.id,
    parentOf: (e) => e.movieId,
    seqOf: (e) => e.episodeNo,
    titleOf: (e) => e.title,
    doneOf: (e) => e.watched,
    dateOf: (e) => e.watchDate,
    ratingOf: (e) => e.rating,
    reviewOf: (e) => e.review,
    imagesOf: (e) => e.images,
    create: ({
      required id,
      required parentId,
      required seq,
      required title,
      required done,
      required date,
      required rating,
      required review,
      required images,
      required createdAt,
      required updatedAt,
    }) => MovieEpisode(
      id: id,
      movieId: parentId,
      episodeNo: seq,
      title: title,
      watched: done,
      watchDate: date,
      rating: rating,
      review: review,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ),
    edit: (e, {seq, title, done, date, rating, review, images, updatedAt}) =>
        e.copyWith(
      episodeNo: seq,
      title: title,
      watched: done,
      watchDate: date,
      rating: rating,
      review: review,
      images: images,
      updatedAt: updatedAt,
    ),
    imagesDir: (parentId, itemId) =>
        ImagePathHelper.instance.getMovieEpisodeImagesDir(parentId, itemId),
  );

  static final ProgressConfig<BookChapter> book = ProgressConfig<BookChapter>(
    listTitle: '章节记录',
    seqLabel: '章节号',
    itemNoun: '第{n}章',
    doneLabel: '已阅读',
    dateLabel: '阅读日期',
    load: (p, id) => p.getBookChapters(id),
    add: (p, c) => p.addBookChapter(c),
    addBatch: (p, list) => p.addBookChaptersBatch(list),
    update: (p, c) => p.updateBookChapter(c),
    remove: (p, id) => p.removeBookChapter(id),
    idOf: (c) => c.id,
    parentOf: (c) => c.bookId,
    seqOf: (c) => c.chapterNo,
    titleOf: (c) => c.title,
    doneOf: (c) => c.read,
    dateOf: (c) => c.readDate,
    ratingOf: (c) => c.rating,
    reviewOf: (c) => c.review,
    imagesOf: (c) => c.images,
    create: ({
      required id,
      required parentId,
      required seq,
      required title,
      required done,
      required date,
      required rating,
      required review,
      required images,
      required createdAt,
      required updatedAt,
    }) => BookChapter(
      id: id,
      bookId: parentId,
      chapterNo: seq,
      title: title,
      read: done,
      readDate: date,
      rating: rating,
      review: review,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ),
    edit: (c, {seq, title, done, date, rating, review, images, updatedAt}) =>
        c.copyWith(
      chapterNo: seq,
      title: title,
      read: done,
      readDate: date,
      rating: rating,
      review: review,
      images: images,
      updatedAt: updatedAt,
    ),
    imagesDir: (parentId, itemId) =>
        ImagePathHelper.instance.getBookChapterImagesDir(parentId, itemId),
  );

  static final ProgressConfig<GameLevel> game = ProgressConfig<GameLevel>(
    listTitle: '关卡记录',
    seqLabel: '关卡号',
    itemNoun: '第{n}关',
    doneLabel: '已通关',
    dateLabel: '通关日期',
    load: (p, id) => p.getGameLevels(id),
    add: (p, l) => p.addGameLevel(l),
    addBatch: (p, list) => p.addGameLevelsBatch(list),
    update: (p, l) => p.updateGameLevel(l),
    remove: (p, id) => p.removeGameLevel(id),
    idOf: (l) => l.id,
    parentOf: (l) => l.gameId,
    seqOf: (l) => l.levelNo,
    titleOf: (l) => l.title,
    doneOf: (l) => l.cleared,
    dateOf: (l) => l.clearDate,
    ratingOf: (l) => l.rating,
    reviewOf: (l) => l.review,
    imagesOf: (l) => l.images,
    create: ({
      required id,
      required parentId,
      required seq,
      required title,
      required done,
      required date,
      required rating,
      required review,
      required images,
      required createdAt,
      required updatedAt,
    }) => GameLevel(
      id: id,
      gameId: parentId,
      levelNo: seq,
      title: title,
      cleared: done,
      clearDate: date,
      rating: rating,
      review: review,
      images: images,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ),
    edit: (l, {seq, title, done, date, rating, review, images, updatedAt}) =>
        l.copyWith(
      levelNo: seq,
      title: title,
      cleared: done,
      clearDate: date,
      rating: rating,
      review: review,
      images: images,
      updatedAt: updatedAt,
    ),
    imagesDir: (parentId, itemId) =>
        ImagePathHelper.instance.getGameLevelImagesDir(parentId, itemId),
  );
}

String _fmtDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 详情页入口卡片：显示 完成数/总数 + 进度条 + 均分，点击进入列表页
class ProgressEntryCard<T> extends StatefulWidget {
  final String parentId;
  final String parentTitle;
  final ProgressConfig<T> config;
  final IconData icon;

  /// 毛玻璃叠层样式（白字透明底）
  final bool frosted;

  const ProgressEntryCard({
    super.key,
    required this.parentId,
    required this.parentTitle,
    required this.config,
    this.icon = Icons.play_circle_outline,
    this.frosted = false,
  });

  @override
  State<ProgressEntryCard<T>> createState() => _ProgressEntryCardState<T>();
}

class _ProgressEntryCardState<T> extends State<ProgressEntryCard<T>> {
  late Future<List<T>> _future;

  void _load() {
    _future = widget.config.load(context.read<AppProvider>(), widget.parentId);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      SlideUpPageRoute(
        page: ProgressListPage<T>(
          parentId: widget.parentId,
          parentTitle: widget.parentTitle,
          config: widget.config,
        ),
      ),
    );
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final frosted = widget.frosted;
    final titleColor = frosted ? Colors.white : colors.onSurface;
    final subColor =
        frosted ? Colors.white.withValues(alpha: 0.5) : colors.onSurface.withValues(alpha: 0.4);

    Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<T>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? <T>[];
          final total = items.length;
          final done = items.where(widget.config.doneOf).length;
          final rated = items.map(widget.config.ratingOf).whereType<double>().toList();
          final avg = rated.isEmpty
              ? null
              : rated.reduce((a, b) => a + b) / rated.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: frosted
                          ? Colors.white.withValues(alpha: 0.7)
                          : colors.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.config.listTitle.tr,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor)),
                  ),
                  if (total > 0)
                    Text('$done / $total',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: frosted ? Colors.white : colors.primary)),
                  Icon(Icons.chevron_right,
                      size: 20,
                      color: frosted
                          ? Colors.white.withValues(alpha: 0.3)
                          : colors.onSurface.withValues(alpha: 0.25)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 5,
                        backgroundColor: frosted
                            ? Colors.white.withValues(alpha: 0.15)
                            : colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  if (avg != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.star,
                        size: 13, color: Color(0xFFFFB800)),
                    const SizedBox(width: 2),
                    Text(avg.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                  if (total == 0) ...[
                    const SizedBox(width: 10),
                    Text('暂无记录'.tr,
                        style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    if (frosted) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _open,
                borderRadius: BorderRadius.circular(12),
                child: content,
              ),
            ),
          ),
        ),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _open,
            borderRadius: BorderRadius.circular(10),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

/// 分集/章节/关卡列表页
class ProgressListPage<T> extends StatefulWidget {
  final String parentId;
  final String parentTitle;
  final ProgressConfig<T> config;

  const ProgressListPage({
    super.key,
    required this.parentId,
    required this.parentTitle,
    required this.config,
  });

  @override
  State<ProgressListPage<T>> createState() => _ProgressListPageState<T>();
}

class _ProgressListPageState<T> extends State<ProgressListPage<T>> {
  List<T> _items = [];
  bool _loading = true;

  ProgressConfig<T> get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _cfg.load(context.read<AppProvider>(), widget.parentId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  int get _doneCount => _items.where(_cfg.doneOf).length;

  double? get _avgRating {
    final rated = _items.map(_cfg.ratingOf).whereType<double>().toList();
    if (rated.isEmpty) return null;
    return rated.reduce((a, b) => a + b) / rated.length;
  }

  Future<void> _toggleDone(T item) async {
    final nowDone = !_cfg.doneOf(item);
    final updated = _cfg.edit(
      item,
      done: nowDone,
      date: nowDone ? (_cfg.dateOf(item) ?? DateTime.now()) : _cfg.dateOf(item),
      updatedAt: DateTime.now(),
    );
    await _cfg.update(context.read<AppProvider>(), updated);
    await _load();
  }

  Future<void> _openEdit({T? existing, int? defaultSeq}) async {
    final changed = await Navigator.push(
      context,
      SlideUpPageRoute(
        page: ProgressEditPage<T>(
          parentId: widget.parentId,
          config: _cfg,
          existing: existing,
          defaultSeq: defaultSeq ??
              (_items.isEmpty
                  ? 1
                  : _items.map(_cfg.seqOf).reduce((a, b) => a > b ? a : b) + 1),
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _batchGenerate() async {
    final provider = context.read<AppProvider>();
    final text = await TextEditSheet.show(
      context: context,
      title: '批量生成'.tr,
      hintText: '请输入总{N}'.trf({'N': _cfg.seqLabel.tr}),
      keyboardType: TextInputType.number,
    );
    if (text == null) return;
    final total = int.tryParse(text.trim());
    if (total == null || total <= 0) {
      if (mounted) ToastUtil.show(context, '请输入有效数字'.tr);
      return;
    }
    if (total > 9999) {
      if (mounted) ToastUtil.show(context, '数量不能超过 9999'.tr);
      return;
    }
    final existingSeqs = _items.map(_cfg.seqOf).toSet();
    final now = DateTime.now();
    final pending = <T>[];
    for (var seq = 1; seq <= total; seq++) {
      if (existingSeqs.contains(seq)) continue;
      pending.add(_cfg.create(
        id: const Uuid().v4(),
        parentId: widget.parentId,
        seq: seq,
        title: '',
        done: false,
        date: null,
        rating: null,
        review: '',
        images: const [],
        createdAt: now,
        updatedAt: now,
      ));
    }
    if (pending.isNotEmpty) {
      await _cfg.addBatch(provider, pending);
    }
    await _load();
  }

  Future<void> _confirmDelete(T item) async {
    appDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('确认删除'.tr),
        content: Text('确定要删除{n}吗？此操作不可恢复。'.trf(
            {'n': _cfg.itemName(_cfg.seqOf(item))})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('取消'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _cfg.remove(context.read<AppProvider>(), _cfg.idOf(item));
              await _load();
            },
            child: Text('删除'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_cfg.listTitle.tr),
        actions: [
          IconButton(
            tooltip: '批量生成'.tr,
            onPressed: _batchGenerate,
            icon: const Icon(Icons.playlist_add_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(colors),
                Expanded(
                  child: _items.isEmpty
                      ? _buildEmpty(colors)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 0.5,
                            indent: 64,
                            color: colors.outlineVariant.withValues(alpha: 0.4),
                          ),
                          itemBuilder: (context, i) =>
                              _buildTile(_items[i], colors),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    final total = _items.length;
    final ratio = total == 0 ? 0.0 : _doneCount / total;
    final avg = _avgRating;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.parentTitle,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '$_doneCount / $total',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary),
              ),
              if (avg != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.star, size: 15, color: Color(0xFFFFB800)),
                Text(avg.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.7))),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: colors.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('暂无记录，点击右下角添加'.tr,
              style: TextStyle(
                  fontSize: 14, color: colors.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Text('或点击右上角「批量生成」'.tr,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildTile(T item, ColorScheme colors) {
    final seq = _cfg.seqOf(item);
    final title = _cfg.titleOf(item);
    final date = _cfg.dateOf(item);
    final rating = _cfg.ratingOf(item);
    final review = _cfg.reviewOf(item);
    final images = _cfg.imagesOf(item);
    final done = _cfg.doneOf(item);

    return InkWell(
      onTap: () => _openEdit(existing: item),
      onLongPress: () => _confirmDelete(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => _toggleDone(item),
                icon: Icon(
                  done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: done ? colors.primary : colors.outline,
                  size: 26,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_cfg.itemName(seq),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? colors.onSurface
                                  : colors.onSurface.withValues(alpha: 0.55))),
                      if (title.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface
                                      .withValues(alpha: done ? 0.9 : 0.5))),
                        ),
                      ],
                    ],
                  ),
                  if (date != null || rating != null || review.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (date != null)
                          Text(_fmtDate(date),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurface
                                      .withValues(alpha: 0.4))),
                        if (date != null && rating != null)
                          const SizedBox(width: 8),
                        if (rating != null) ...[
                          const Icon(Icons.star,
                              size: 12, color: Color(0xFFFFB800)),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurface
                                      .withValues(alpha: 0.5))),
                        ],
                        if (review.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(review,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.4))),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FadeInLocalImage(
                          path: images.first, fit: BoxFit.cover),
                      if (images.length > 1)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${images.length}',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 分集/章节/关卡编辑页
class ProgressEditPage<T> extends StatefulWidget {
  final String parentId;
  final ProgressConfig<T> config;
  final T? existing;
  final int defaultSeq;

  const ProgressEditPage({
    super.key,
    required this.parentId,
    required this.config,
    this.existing,
    required this.defaultSeq,
  });

  @override
  State<ProgressEditPage<T>> createState() => _ProgressEditPageState<T>();
}

class _ProgressEditPageState<T> extends State<ProgressEditPage<T>> {
  late int _seq;
  late TextEditingController _titleController;
  late TextEditingController _reviewController;
  late bool _done;
  DateTime? _date;
  double? _rating;
  late List<String> _images;
  String? _tempId;

  ProgressConfig<T> get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _seq = e == null ? widget.defaultSeq : _cfg.seqOf(e);
    _titleController =
        TextEditingController(text: e == null ? '' : _cfg.titleOf(e));
    _reviewController =
        TextEditingController(text: e == null ? '' : _cfg.reviewOf(e));
    _done = e == null ? false : _cfg.doneOf(e);
    _date = e == null ? null : _cfg.dateOf(e);
    _rating = e == null ? null : _cfg.ratingOf(e);
    _images = e == null ? [] : List<String>.from(_cfg.imagesOf(e));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final files = await pickLocalImages(context);
      if (!mounted || files.isEmpty) return;
      final itemId = widget.existing != null
          ? _cfg.idOf(widget.existing as T)
          : (_tempId ??= const Uuid().v4());
      final targetDir = await _cfg.imagesDir(widget.parentId, itemId);
      await ImagePathHelper.instance.ensureDirExists(targetDir);
      final newPaths = <String>[];
      for (final file in files) {
        final ext = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${newPaths.length}$ext';
        final targetPath = p.join(targetDir, fileName);
        await file.copy(targetPath);
        newPaths.add(targetPath);
      }
      if (mounted) setState(() => _images.addAll(newPaths));
    } catch (e) {
      if (mounted) ToastUtil.show(context, '选择图片失败: {e}'.trf({'e': e}));
    }
  }

  /// 新建保存时把图片从临时ID目录移到正式ID目录
  Future<List<String>> _moveImagesToNewId(String oldId, String newId) async {
    final newPaths = <String>[];
    final newDir = await _cfg.imagesDir(widget.parentId, newId);
    for (final imagePath in _images) {
      final normalized = imagePath.replaceAll('\\', '/');
      final marker = '/$oldId/';
      if (normalized.contains(marker)) {
        final fileName = p.basename(imagePath);
        final newPath = p.join(newDir, fileName);
        await ImagePathHelper.instance.ensureDirExists(newDir);
        final sourceFile = File(imagePath);
        if (await sourceFile.exists()) {
          await sourceFile.rename(newPath);
          await ImageAssetDao().onFileMoved(imagePath, newPath);
          newPaths.add(newPath);
        } else {
          newPaths.add(imagePath);
        }
      } else {
        newPaths.add(imagePath);
      }
    }
    return newPaths;
  }

  Future<void> _save() async {
    final provider = context.read<AppProvider>();
    try {
      final now = DateTime.now();
      if (widget.existing == null) {
        final id = const Uuid().v4();
        var images = _images;
        if (_images.isNotEmpty && _tempId != null) {
          images = await _moveImagesToNewId(_tempId!, id);
        }
        await _cfg.add(
          provider,
          _cfg.create(
            id: id,
            parentId: widget.parentId,
            seq: _seq,
            title: _titleController.text.trim(),
            done: _done,
            date: _done ? (_date ?? DateTime.now()) : null,
            rating: _rating,
            review: _reviewController.text.trim(),
            images: images,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await _cfg.update(
          provider,
          _cfg.edit(
            widget.existing as T,
            seq: _seq,
            title: _titleController.text.trim(),
            done: _done,
            date: _done ? (_date ?? DateTime.now()) : null,
            rating: _rating,
            review: _reviewController.text.trim(),
            images: _images,
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      ToastUtil.show(context, '保存成功'.tr);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ToastUtil.show(context, '保存失败: {e}'.trf({'e': e}));
    }
  }

  Future<void> _editSeq() async {
    final text = await TextEditSheet.show(
      context: context,
      title: _cfg.seqLabel.tr,
      initialText: '$_seq',
      keyboardType: TextInputType.number,
    );
    if (text == null) return;
    final v = int.tryParse(text.trim());
    if (v == null || v <= 0) {
      if (mounted) ToastUtil.show(context, '请输入有效数字'.tr);
      return;
    }
    if (mounted) setState(() => _seq = v);
  }

  Future<void> _editTitle() async {
    final text = await TextEditSheet.show(
      context: context,
      title: '名称（选填）'.tr,
      initialText: _titleController.text,
    );
    if (text != null && mounted) setState(() => _titleController.text = text);
  }

  Future<void> _editReview() async {
    final text = await TextEditSheet.show(
      context: context,
      title: '评价（选填）'.tr,
      initialText: _reviewController.text,
      multiline: true,
    );
    if (text != null && mounted) setState(() => _reviewController.text = text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? '添加{n}'.trf({'n': _cfg.itemName(_seq)})
            : '编辑{n}'.trf({'n': _cfg.itemName(_seq)})),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildCard(
                  colors,
                  [
                    _buildRow(
                      icon: Icons.numbers,
                      label: _cfg.seqLabel.tr,
                      value: '$_seq',
                      onTap: _editSeq,
                      colors: colors,
                    ),
                    _divider(colors),
                    _buildRow(
                      icon: Icons.title,
                      label: '名称'.tr,
                      value: _titleController.text.isEmpty
                          ? '选填'.tr
                          : _titleController.text,
                      onTap: _editTitle,
                      colors: colors,
                      muted: _titleController.text.isEmpty,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusCard(colors),
                const SizedBox(height: 12),
                _buildCard(
                  colors,
                  [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: _buildRating(colors),
                    ),
                    _divider(colors),
                    _buildRow(
                      icon: Icons.rate_review_outlined,
                      label: '评价'.tr,
                      value: _reviewController.text.isEmpty
                          ? '选填'.tr
                          : _reviewController.text,
                      onTap: _editReview,
                      colors: colors,
                      muted: _reviewController.text.isEmpty,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text('截图'.tr,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface.withValues(alpha: 0.55))),
                ),
                ImageGridEditor(
                  images: _images,
                  onAdd: _pickImages,
                  onRemove: (i) => setState(() => _images.removeAt(i)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                  top: BorderSide(
                      color: colors.outlineVariant, width: 0.5)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('保存'.tr,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ColorScheme colors, List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ColorScheme colors) {
    return Divider(
      height: 1,
      indent: 42,
      color: colors.outlineVariant.withValues(alpha: 0.45),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required ColorScheme colors,
    bool muted = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 19, color: colors.onSurface.withValues(alpha: 0.42)),
            const SizedBox(width: 9),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.62))),
            const Spacer(),
            Flexible(
              child: Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 14,
                      color: muted
                          ? colors.onSurface.withValues(alpha: 0.32)
                          : colors.onSurface)),
            ),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right,
                size: 18, color: colors.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colors) {
    final activeColor = _done ? colors.primary : colors.outline;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _done
            ? colors.primaryContainer.withValues(alpha: 0.45)
            : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _done = !_done;
              if (_done && _date == null) _date = DateTime.now();
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 8, 5),
              child: Row(
                children: [
                  Icon(_done ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 20, color: activeColor),
                  const SizedBox(width: 9),
                  Text(_cfg.doneLabel.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _done
                            ? colors.onSurface
                            : colors.onSurface.withValues(alpha: 0.62),
                      )),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: _done,
                      onChanged: (v) => setState(() {
                        _done = v;
                        if (v && _date == null) _date = DateTime.now();
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_done) ...[
            _divider(colors),
            _buildRow(
              icon: Icons.event_outlined,
              label: _cfg.dateLabel.tr,
              value: _date == null ? '未选择'.tr : _fmtDate(_date!),
              muted: _date == null,
              onTap: () async {
                final picked = await showDatePickerSheet(
                  context: context,
                  title: _cfg.dateLabel.tr,
                  initial: _date ?? DateTime.now(),
                );
                if (picked != null && mounted) setState(() => _date = picked);
              },
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRating(ColorScheme colors) {
    return Row(
      children: [
        Text('评分'.tr,
            style: TextStyle(
                fontSize: 14, color: colors.onSurface.withValues(alpha: 0.62))),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(10, (i) {
                  final v = i + 1;
                  final filled = _rating != null && _rating! >= v;
                  return InkWell(
                    onTap: () => setState(() {
                      _rating = (_rating != null && _rating == v.toDouble())
                          ? null
                          : v.toDouble();
                    }),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 24,
                      color: const Color(0xFFFFB800),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
