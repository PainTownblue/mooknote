import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/bangumi_service.dart';
import '../../utils/slide_up_page_route.dart';
import '../../utils/toast_util.dart';
import '../../utils/user_prefs.dart';
import 'bangumi_detail_page.dart';

/// Bangumi 条目类型标签：1=书籍 2=动画 4=游戏 6=三次元
String bangumiTypeLabel(int type) {
  switch (type) {
    case 1:
      return '书籍'.tr;
    case 2:
      return '动画'.tr;
    case 4:
      return '游戏'.tr;
    case 6:
      return '三次元'.tr;
    default:
      return '其他'.tr;
  }
}

/// Bangumi 搜索 body —— 可嵌入到统一搜索页 SearchHubPage
class BangumiSearchPageBody extends StatefulWidget {
  const BangumiSearchPageBody({super.key});

  @override
  State<BangumiSearchPageBody> createState() => _BangumiSearchPageBodyState();
}

class _BangumiSearchPageBodyState extends State<BangumiSearchPageBody> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _userPrefs = UserPrefs();
  final _bgm = BangumiService.instance;

  String _query = '';
  bool _hasSearched = false;
  List<String> _history = [];

  List<Map<String, dynamic>> _list = [];
  int _offset = 0;
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _tokenInvalid = false;
  int _callSeq = 0; // 请求代次，旧响应作废

  bool get _hasMore => _list.length < _total;

  @override
  void initState() {
    super.initState();
    _bgm.configure(_userPrefs.bangumiAccessToken,
        proxy: _userPrefs.bangumiProxy);
    _history = _userPrefs.searchHistory;
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          !_loadingMore &&
          _hasMore) {
        _search(_query, _offset);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _doSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty || keyword == _query && _hasSearched) return;
    setState(() {
      _query = keyword;
      _hasSearched = true;
      _list = [];
      _offset = 0;
      _total = 0;
      _loadingMore = false;
    });
    _userPrefs.addSearchHistory(keyword);
    _history = _userPrefs.searchHistory;
    _search(keyword, 0);
  }

  Future<void> _search(String keyword, int offset) async {
    final callSeq = ++_callSeq;
    if (_userPrefs.bangumiAccessToken.isEmpty) {
      if (callSeq == _callSeq) ToastUtil.show(context, '请先在设置中配置 Bangumi Token'.tr);
      return;
    }

    setState(() {
      if (offset == 0) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final data = await _bgm.searchSubjects(keyword, offset);
      if (!mounted || callSeq != _callSeq) return;
      final list = (data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        if (offset == 0) {
          _list = list;
        } else {
          _list.addAll(list);
        }
        _offset = offset + list.length;
        _total = (data['total'] as num?)?.toInt() ?? _list.length;
        _tokenInvalid = false;
      });
    } on BangumiAuthException {
      if (mounted && callSeq == _callSeq) setState(() => _tokenInvalid = true);
    } on BangumiNetworkException {
      if (mounted && callSeq == _callSeq) ToastUtil.show(context, '搜索失败，请检查网络'.tr);
    }

    if (mounted && callSeq == _callSeq) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: Column(
        children: [
          // 搜索栏 + 搜索按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar(colors)),
                TextButton(
                  onPressed: _doSearch,
                  child: Text('搜索'.tr,
                      style: TextStyle(fontSize: 14, color: colors.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _hasSearched ? _buildResults(colors) : _buildHistoryPanel(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search,
              size: 16, color: colors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13, color: colors.onSurface),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索动画、书籍、游戏...'.tr,
                hintStyle: TextStyle(
                    fontSize: 13, color: colors.onSurface.withValues(alpha: 0.3)),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onSubmitted: (_) => _doSearch(),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _hasSearched = false;
                  _list = [];
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.close,
                    size: 15, color: colors.onSurface.withValues(alpha: 0.3)),
              ),
            ),
          if (_query.isEmpty) const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ── 结果列表 ──────────────────────────────────────────────

  Widget _buildResults(ColorScheme colors) {
    if (_tokenInvalid) {
      return _buildEmptyState(
          colors, 'Token 已失效，请前往设置重新验证'.tr, Icons.vpn_key_outlined);
    }
    if (_loading) return _buildLoadingState(colors);
    if (_list.isEmpty) {
      return _buildEmptyState(colors, '未找到相关内容'.tr, Icons.search_off_outlined);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _list.length + 1,
      itemBuilder: (context, index) {
        if (index == _list.length) {
          return _buildBottomIndicator(colors, _hasMore);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.push(
                context, SlideUpPageRoute(page: BangumiDetailPage(item: _list[index]))),
            child: _buildCard(colors, _list[index]),
          ),
        );
      },
    );
  }

  Widget _buildCard(ColorScheme colors, Map<String, dynamic> item) {
    final type = (item['type'] as num?)?.toInt() ?? 0;
    final nameCn = (item['name_cn'] ?? '').toString();
    final name = (item['name'] ?? '').toString();
    final title = nameCn.isNotEmpty ? nameCn : name;
    final dateStr = (item['date'] ?? '').toString();
    final year = dateStr.length >= 4 ? dateStr.substring(0, 4) : '';
    final cover = (item['images']?['common'] ?? '').toString();
    final rating = (item['rating']?['score'] as num?)?.toDouble() ?? 0;
    final summary = (item['summary'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面
            SizedBox(
              width: 100,
              child: cover.isNotEmpty
                  ? Image.network(cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(colors))
                  : _coverPlaceholder(colors),
            ),
            // 信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：标题 + 类型标签
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        _buildTypeTag(colors, type),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 第二行：年份 + 评分
                    Row(
                      children: [
                        if (year.isNotEmpty)
                          Text(year,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.4))),
                        if (rating > 0) ...[
                          if (year.isNotEmpty) const SizedBox(width: 8),
                          Icon(Icons.star_rounded,
                              size: 13, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.4))),
                        ],
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(summary,
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.5),
                              height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String typeLabel(int type) => bangumiTypeLabel(type);

  Widget _buildTypeTag(ColorScheme colors, int type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(typeLabel(type),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: colors.primary)),
    );
  }

  Widget _coverPlaceholder(ColorScheme colors) {
    return Container(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 28, color: colors.onSurface.withValues(alpha: 0.2)),
      ),
    );
  }

  // ── 通用状态 ──────────────────────────────────────────────

  Widget _buildHistoryPanel(ColorScheme colors) {
    if (_history.isEmpty) {
      return _buildEmptyState(
          colors, '搜索你想找的动画、书籍或游戏'.tr, Icons.explore_outlined);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Text('搜索历史'.tr,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _userPrefs.clearSearchHistory();
                setState(() => _history = []);
              },
              child: Text('清空'.tr,
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurface.withValues(alpha: 0.4))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _history
              .map((h) => GestureDetector(
                    onTap: () {
                      _searchController.text = h;
                      _doSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: colors.outlineVariant, width: 0.5),
                      ),
                      child: Text(h,
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.6))),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colors, String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: colors.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 13, color: colors.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child:
                CircularProgressIndicator(strokeWidth: 2.5, color: colors.primary),
          ),
          const SizedBox(height: 16),
          Text('正在搜索...'.tr,
              style: TextStyle(
                  fontSize: 13, color: colors.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildBottomIndicator(ColorScheme colors, bool hasMore) {
    if (hasMore && _loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: colors.primary)),
            const SizedBox(width: 8),
            Text('加载中...'.tr,
                style: TextStyle(
                    fontSize: 12, color: colors.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container(height: 0.5, color: colors.outlineVariant)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              hasMore ? '' : '已经是所有数据啦'.tr,
              style: TextStyle(
                  fontSize: 11, color: colors.onSurface.withValues(alpha: 0.3)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 0.5, color: colors.outlineVariant)),
        ],
      ),
    );
  }
}
