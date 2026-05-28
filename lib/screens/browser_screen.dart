import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/browser_state.dart';
import '../theme/app_theme.dart';
import '../features/ad_blocker.dart';
import '../features/ai_assistant.dart';
import '../screens/home_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen>
    with TickerProviderStateMixin {
  late AnimationController _navAnim;
  bool _navVisible = true;
  double _lastScroll = 0;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  void _toggleNav(bool show) {
    if (show == _navVisible) return;
    _navVisible = show;
    if (show) {
      _navAnim.forward();
    } else {
      _navAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: LightTheme.darkBg,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // ── ADDRESS BAR ──
            _AddressBar(
              tab: state.activeTab,
              onNavigate: (url) {
                state.activeTab?.controller?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(url)),
                );
              },
              onReload: () => state.activeTab?.controller?.reload(),
              onMenu: () => _showMenu(context, state),
            ),

            // ── PROGRESS BAR ──
            if ((state.activeTab?.progress ?? 0) > 0 &&
                (state.activeTab?.progress ?? 0) < 1)
              LinearProgressIndicator(
                value: state.activeTab?.progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  state.isPrivateMode ? LightTheme.primary2 : LightTheme.primary,
                ),
              ),

            // ── TAB BAR ──
            if (state.tabs.length > 1)
              _TabBar(
                tabs: state.tabs,
                activeIndex: state.activeIndex,
                onSwitch: state.switchTab,
                onClose: state.closeTab,
                onAdd: () => state.addTab(),
              ),

            // ── WEB VIEW / HOME ──
            Expanded(
              child: IndexedStack(
                index: state.activeIndex,
                children: state.tabs.map((tab) {
                  if (tab.url == 'light://home') {
                    return HomeScreen(
                      onNavigate: (url) {
                        state.updateTab(tab.id, url: url);
                        tab.controller?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(url)),
                        );
                      },
                    );
                  }
                  return _WebTab(
                    key: ValueKey(tab.id),
                    tab: tab,
                    onCreated: (ctrl) => state.setController(tab.id, ctrl),
                    onTitleChanged: (t) => state.updateTab(tab.id, title: t),
                    onUrlChanged: (u) => state.updateTab(tab.id, url: u),
                    onLoadStart: () => state.updateTab(tab.id, isLoading: true),
                    onLoadStop: () => state.updateTab(tab.id, isLoading: false, progress: 0),
                    onProgress: (p) => state.updateTab(tab.id, progress: p / 100),
                    onScroll: (dy) => _toggleNav(dy <= 0 || dy < _lastScroll.abs()),
                    adBlockEnabled: state.adBlockEnabled,
                    forceDark: state.forceDark,
                    isPrivate: tab.isPrivate,
                  );
                }).toList(),
              ),
            ),
          ]),

          // ── BOTTOM NAV (auto-hide) ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SizeTransition(
              sizeFactor: _navAnim,
              axisAlignment: -1,
              child: _BottomNav(
                state: state,
                onBack: () => state.activeTab?.controller?.goBack(),
                onForward: () => state.activeTab?.controller?.goForward(),
                onHome: () {
                  state.activeTab?.controller?.loadUrl(
                    urlRequest: URLRequest(url: WebUri('light://home')),
                  );
                },
                onTabs: () => _showTabSwitcher(context, state),
                onAI: () => _showAiPanel(context, state),
              ),
            ),
          ),

          // ── AI PANEL ──
          if (state.aiPanelOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: state.toggleAiPanel,
                child: Container(color: Colors.black54),
              ),
            ),
          if (state.aiPanelOpen)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AiAssistantPanel(
                currentUrl: state.activeTab?.url ?? '',
                getPageText: () async {
                  final result = await state.activeTab?.controller
                      ?.evaluateJavascript(source: 'document.body.innerText');
                  return result?.toString() ?? '';
                },
                onClose: state.toggleAiPanel,
              ),
            ),
        ]),
      ),
    );
  }

  void _showMenu(BuildContext context, BrowserState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LightTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BrowserMenu(state: state),
    );
  }

  void _showTabSwitcher(BuildContext context, BrowserState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LightTheme.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TabSwitcherSheet(state: state),
    );
  }

  void _showAiPanel(BuildContext context, BrowserState state) {
    state.toggleAiPanel();
  }
}

// ── ADDRESS BAR ───────────────────────────────────────────
class _AddressBar extends StatefulWidget {
  final BrowserTab? tab;
  final Function(String) onNavigate;
  final VoidCallback onReload;
  final VoidCallback onMenu;

  const _AddressBar({
    required this.tab,
    required this.onNavigate,
    required this.onReload,
    required this.onMenu,
  });

  @override
  State<_AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<_AddressBar> {
  final _ctrl = TextEditingController();
  bool _editing = false;
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(_AddressBar old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.tab?.url != old.tab?.url) {
      _ctrl.text = _displayUrl(widget.tab?.url ?? '');
    }
  }

  String _displayUrl(String url) {
    if (url == 'light://home' || url == 'about:blank') return '';
    return url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceFirst('www.', '');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();
    final isPrivate = state.activeTab?.isPrivate ?? false;
    final url = widget.tab?.url ?? '';
    final isSecure = url.startsWith('https');

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isPrivate ? const Color(0xFF1A0A2E) : LightTheme.darkSurface,
        border: Border(
          bottom: BorderSide(color: LightTheme.darkBorder),
        ),
      ),
      child: Row(children: [
        // Logo
        _LogoMark(private: isPrivate),
        const SizedBox(width: 8),

        // URL Bar
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _editing = true);
              _ctrl.text = widget.tab?.url ?? '';
              _ctrl.selectAll();
              _focusNode.requestFocus();
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _editing
                    ? LightTheme.darkSurface2
                    : LightTheme.darkSurface2.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _editing ? LightTheme.primary.withOpacity(0.5) : LightTheme.darkBorder,
                ),
              ),
              child: Row(children: [
                if (!_editing)
                  Icon(
                    isSecure ? Icons.lock_outline : Icons.lock_open_outlined,
                    size: 12,
                    color: isSecure ? LightTheme.accent : LightTheme.warning,
                  ),
                if (!_editing) const SizedBox(width: 6),
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          style: GoogleFonts.spaceGrotesk(
                            color: LightTheme.darkText,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (v) {
                            setState(() => _editing = false);
                            widget.onNavigate(state.resolveUrl(v));
                          },
                          onEditingComplete: () => setState(() => _editing = false),
                        )
                      : Text(
                          _displayUrl(url).isEmpty ? 'Search or enter URL' : _displayUrl(url),
                          style: GoogleFonts.spaceGrotesk(
                            color: _displayUrl(url).isEmpty
                                ? LightTheme.darkTextSec
                                : LightTheme.darkText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (widget.tab?.isLoading == true)
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(LightTheme.primary),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: widget.onReload,
                    child: Icon(Icons.refresh, size: 14, color: LightTheme.darkTextSec),
                  ),
              ]),
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Menu
        GestureDetector(
          onTap: widget.onMenu,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: LightTheme.darkSurface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, color: LightTheme.darkTextSec, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ── LOGO ─────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final bool private;
  const _LogoMark({this.private = false});

  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      gradient: private
          ? const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF2F0080)])
          : LightGradients.brand,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Text(
        private ? '🔒' : 'L',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

// ── WEB TAB ───────────────────────────────────────────────
class _WebTab extends StatelessWidget {
  final BrowserTab tab;
  final Function(InAppWebViewController) onCreated;
  final Function(String) onTitleChanged;
  final Function(String) onUrlChanged;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadStop;
  final Function(int) onProgress;
  final Function(double) onScroll;
  final bool adBlockEnabled;
  final bool forceDark;
  final bool isPrivate;

  const _WebTab({
    super.key,
    required this.tab,
    required this.onCreated,
    required this.onTitleChanged,
    required this.onUrlChanged,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onProgress,
    required this.onScroll,
    required this.adBlockEnabled,
    required this.forceDark,
    required this.isPrivate,
  });

  @override
  Widget build(BuildContext context) {
    final adblocker = AdBlocker();

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(
        tab.url == 'light://home' ? 'https://www.google.com' : tab.url,
      )),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: !isPrivate,
        cacheEnabled: !isPrivate,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: true,
        useOnDownloadStart: true,
        allowContentAccess: true,
        geolocationEnabled: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Mobile Safari/537.36',
        transparentBackground: true,
      ),
      onWebViewCreated: onCreated,
      onLoadStart: (c, url) {
        onLoadStart();
        if (url != null) onUrlChanged(url.toString());
      },
      onLoadStop: (c, url) {
        onLoadStop();
        if (url != null) onUrlChanged(url.toString());
        // Inject force dark if enabled
        if (forceDark) {
          c.injectCSSCode(source: BrowserState.forceDarkCSS);
        }
      },
      onTitleChanged: (c, title) {
        if (title != null) onTitleChanged(title);
      },
      onProgressChanged: (c, progress) {
        onProgress(progress);
      },
      onScrollChanged: (c, x, y) {
        onScroll(y.toDouble());
      },
      shouldOverrideUrlLoading: (c, action) async {
        final url = action.request.url?.toString() ?? '';
        if (adBlockEnabled && adblocker.shouldBlock(url)) {
          BlockStats.increment();
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
      onDownloadStartRequest: (c, request) {
        _handleDownload(context, request.url.toString());
      },
    );
  }

  void _handleDownload(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading: ${Uri.parse(url).pathSegments.last}'),
        backgroundColor: LightTheme.darkSurface,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: LightTheme.primary,
          onPressed: () {},
        ),
      ),
    );
  }
}

// ── TAB BAR ───────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final List<BrowserTab> tabs;
  final int activeIndex;
  final Function(int) onSwitch;
  final Function(String) onClose;
  final VoidCallback onAdd;

  const _TabBar({
    required this.tabs,
    required this.activeIndex,
    required this.onSwitch,
    required this.onClose,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    color: LightTheme.darkSurface,
    child: Row(children: [
      Expanded(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          itemCount: tabs.length,
          itemBuilder: (ctx, i) {
            final tab = tabs[i];
            final active = i == activeIndex;
            return GestureDetector(
              onTap: () => onSwitch(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: active ? LightTheme.darkSurface2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: active
                      ? Border.all(color: LightTheme.primary.withOpacity(0.5))
                      : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (tab.isPrivate)
                    const Icon(Icons.lock, size: 10, color: LightTheme.primary2),
                  if (tab.isPrivate) const SizedBox(width: 4),
                  Text(
                    tab.title.length > 14 ? '${tab.title.substring(0, 14)}…' : tab.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: active ? LightTheme.primary : LightTheme.darkTextSec,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onClose(tab.id),
                    child: Icon(Icons.close, size: 10, color: LightTheme.darkTextSec),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 16, color: LightTheme.darkTextSec),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    ]),
  );
}

// ── BOTTOM NAV ────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final BrowserState state;
  final VoidCallback onBack, onForward, onHome, onTabs, onAI;

  const _BottomNav({
    required this.state,
    required this.onBack,
    required this.onForward,
    required this.onHome,
    required this.onTabs,
    required this.onAI,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(
      color: LightTheme.darkSurface,
      border: const Border(top: BorderSide(color: LightTheme.darkBorder)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(children: [
      _NavBtn(icon: Icons.arrow_back_ios_new, onTap: onBack, size: 18),
      _NavBtn(icon: Icons.arrow_forward_ios, onTap: onForward, size: 18),
      _NavBtn(icon: Icons.home_outlined, onTap: onHome, size: 22),
      // AI Button
      Expanded(
        child: GestureDetector(
          onTap: onAI,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ShaderMask(
              shaderCallback: (b) => LightGradients.brand.createShader(b),
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            ),
          ]),
        ),
      ),
      // Tabs button
      Expanded(
        child: GestureDetector(
          onTap: onTabs,
          child: Center(
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: LightTheme.darkTextSec, width: 2),
              ),
              child: Center(
                child: Text(
                  state.tabs.length.toString(),
                  style: GoogleFonts.spaceGrotesk(
                    color: LightTheme.darkTextSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _NavBtn({required this.icon, required this.onTap, this.size = 20});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Center(
        child: Icon(icon, size: size, color: LightTheme.darkTextSec),
      ),
    ),
  );
}

// ── BROWSER MENU ─────────────────────────────────────────
class _BrowserMenu extends StatelessWidget {
  final BrowserState state;
  const _BrowserMenu({required this.state});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: LightTheme.darkBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      // Feature toggles
      _MenuItem(
        icon: Icons.block,
        label: 'Ad Block',
        value: state.adBlockEnabled,
        onToggle: (_) => state.toggleAdBlock(),
        color: LightTheme.accent,
      ),
      _MenuItem(
        icon: Icons.dark_mode,
        label: 'Force Dark Mode',
        value: state.forceDark,
        onToggle: (_) => state.toggleForceDark(),
        color: LightTheme.primary,
      ),
      _MenuItem(
        icon: Icons.lock,
        label: 'Private Mode',
        value: state.isPrivateMode,
        onToggle: (_) => state.togglePrivateMode(),
        color: LightTheme.primary2,
      ),
      const Divider(color: LightTheme.darkBorder),
      // Actions
      _MenuAction(
        icon: Icons.bookmark_border,
        label: 'Bookmark This Page',
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark saved!')),
          );
        },
      ),
      _MenuAction(
        icon: Icons.share_outlined,
        label: 'Share Page',
        onTap: () => Navigator.pop(context),
      ),
      _MenuAction(
        icon: Icons.download_outlined,
        label: 'Save Page',
        onTap: () => Navigator.pop(context),
      ),
      _MenuAction(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/settings');
        },
      ),
      const SizedBox(height: 8),
    ]),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Function(bool) onToggle;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color, size: 20),
    title: Text(label, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkText, fontSize: 14,
    )),
    trailing: Switch.adaptive(
      value: value,
      onChanged: onToggle,
      activeColor: color,
    ),
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: LightTheme.darkTextSec, size: 20),
    title: Text(label, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkText, fontSize: 14,
    )),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}

// ── TAB SWITCHER ─────────────────────────────────────────
class _TabSwitcherSheet extends StatelessWidget {
  final BrowserState state;
  const _TabSwitcherSheet({required this.state});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    minChildSize: 0.3,
    expand: false,
    builder: (ctx, scroll) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: LightTheme.darkBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Row(children: [
          Text('${state.tabs.length} Tabs', style: GoogleFonts.spaceGrotesk(
            color: LightTheme.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              state.addTab();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Tab'),
            style: TextButton.styleFrom(foregroundColor: LightTheme.primary),
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            controller: scroll,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: state.tabs.length,
            itemBuilder: (ctx, i) {
              final tab = state.tabs[i];
              final active = i == state.activeIndex;
              return GestureDetector(
                onTap: () {
                  state.switchTab(i);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: LightTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? LightTheme.primary : LightTheme.darkBorder,
                      width: active ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (tab.isPrivate)
                          const Icon(Icons.lock, size: 10, color: LightTheme.primary2),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => state.closeTab(tab.id),
                          child: const Icon(Icons.close, size: 14, color: LightTheme.darkTextSec),
                        ),
                      ]),
                      const Spacer(),
                      Text(
                        tab.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: LightTheme.darkText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.url.replaceFirst('https://', '').replaceFirst('www.', ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: LightTheme.darkTextSec,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    ),
  );
}
