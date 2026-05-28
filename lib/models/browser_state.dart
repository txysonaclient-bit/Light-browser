import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ── TAB MODEL ──────────────────────────────────────────────
class BrowserTab {
  final String id;
  String title;
  String url;
  String? favicon;
  bool isLoading;
  bool isPrivate;
  double progress;
  InAppWebViewController? controller;
  WebUri? previewUrl;

  BrowserTab({
    required this.id,
    this.title = 'New Tab',
    this.url = 'about:blank',
    this.favicon,
    this.isLoading = false,
    this.isPrivate = false,
    this.progress = 0,
    this.controller,
  });

  BrowserTab copyWith({
    String? title,
    String? url,
    String? favicon,
    bool? isLoading,
    double? progress,
  }) =>
      BrowserTab(
        id: id,
        title: title ?? this.title,
        url: url ?? this.url,
        favicon: favicon ?? this.favicon,
        isLoading: isLoading ?? this.isLoading,
        isPrivate: isPrivate,
        progress: progress ?? this.progress,
        controller: controller,
      );
}

// ── BOOKMARK MODEL ─────────────────────────────────────────
class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? favicon;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'favicon': favicon,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(
    id: m['id'],
    title: m['title'],
    url: m['url'],
    favicon: m['favicon'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );
}

// ── HISTORY MODEL ──────────────────────────────────────────
class HistoryItem {
  final String id;
  final String title;
  final String url;
  final DateTime visitedAt;

  HistoryItem({
    required this.id,
    required this.title,
    required this.url,
    required this.visitedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'visitedAt': visitedAt.millisecondsSinceEpoch,
  };

  factory HistoryItem.fromMap(Map<String, dynamic> m) => HistoryItem(
    id: m['id'],
    title: m['title'],
    url: m['url'],
    visitedAt: DateTime.fromMillisecondsSinceEpoch(m['visitedAt']),
  );
}

// ── BROWSER STATE ──────────────────────────────────────────
class BrowserState extends ChangeNotifier {
  List<BrowserTab> _tabs = [];
  int _activeIndex = 0;
  bool _isDark = true;
  bool _adBlockEnabled = true;
  bool _forceDark = false;
  bool _readerMode = false;
  bool _aiPanelOpen = false;
  bool _isPrivateMode = false;
  String _searchEngine = 'google';

  List<BrowserTab> get tabs => _tabs;
  int get activeIndex => _activeIndex;
  BrowserTab? get activeTab =>
      _tabs.isEmpty ? null : _tabs[_activeIndex];
  bool get isDark => _isDark;
  bool get adBlockEnabled => _adBlockEnabled;
  bool get forceDark => _forceDark;
  bool get readerMode => _readerMode;
  bool get aiPanelOpen => _aiPanelOpen;
  bool get isPrivateMode => _isPrivateMode;
  String get searchEngine => _searchEngine;

  BrowserState() {
    addTab();
  }

  // ── Tab Management ──
  void addTab({String url = 'light://home', bool private = false}) {
    final tab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      isPrivate: private,
    );
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(String id) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tabs.removeAt(idx);
    if (_tabs.isEmpty) {
      addTab();
    } else {
      _activeIndex = (_activeIndex >= _tabs.length)
          ? _tabs.length - 1
          : _activeIndex;
    }
    notifyListeners();
  }

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void updateTab(String id, {
    String? title,
    String? url,
    bool? isLoading,
    double? progress,
    String? favicon,
  }) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final tab = _tabs[idx];
    _tabs[idx] = tab.copyWith(
      title: title,
      url: url,
      isLoading: isLoading,
      progress: progress,
      favicon: favicon,
    );
    notifyListeners();
  }

  void setController(String id, InAppWebViewController controller) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tabs[idx].controller = controller;
    }
  }

  // ── Settings ──
  void toggleDark() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void toggleAdBlock() {
    _adBlockEnabled = !_adBlockEnabled;
    notifyListeners();
  }

  void toggleForceDark() {
    _forceDark = !_forceDark;
    activeTab?.controller?.injectCSSCode(source: _forceDark
        ? forceDarkCSS
        : 'html{filter:none!important}');
    notifyListeners();
  }

  void toggleReaderMode() {
    _readerMode = !_readerMode;
    notifyListeners();
  }

  void toggleAiPanel() {
    _aiPanelOpen = !_aiPanelOpen;
    notifyListeners();
  }

  void togglePrivateMode() {
    _isPrivateMode = !_isPrivateMode;
    addTab(private: _isPrivateMode);
    notifyListeners();
  }

  void setSearchEngine(String engine) {
    _searchEngine = engine;
    notifyListeners();
  }

  String buildSearchUrl(String query) {
    final q = Uri.encodeComponent(query);
    switch (_searchEngine) {
      case 'bing': return 'https://www.bing.com/search?q=$q';
      case 'duckduckgo': return 'https://duckduckgo.com/?q=$q';
      case 'brave': return 'https://search.brave.com/search?q=$q';
      default: return 'https://www.google.com/search?q=$q';
    }
  }

  String resolveUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // IP address
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
    if (ipRegex.hasMatch(trimmed)) return 'http://$trimmed';
    // Domain
    if (trimmed.contains('.') && !trimmed.contains(' ') && trimmed.length > 3) {
      return 'https://$trimmed';
    }
    return buildSearchUrl(trimmed);
  }

  static const forceDarkCSS = '''
    html {
      filter: invert(1) hue-rotate(180deg) !important;
    }
    img, video, canvas, svg, [style*="background-image"] {
      filter: invert(1) hue-rotate(180deg) !important;
    }
  ''';
}
