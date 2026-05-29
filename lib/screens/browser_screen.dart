import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/browser_state.dart';
import '../theme/app_theme.dart';
import '../features/ad_blocker.dart';
import 'home_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});
  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
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
        child: Column(children: [
          // Address bar
          _AddressBar(
            tab: state.activeTab,
            onNavigate: (url) {
              state.activeTab?.controller?.loadUrl(
                urlRequest: URLRequest(url: WebUri(url)),
              );
              state.updateTab(state.activeTab!.id, url: url);
            },
            onReload: () => state.activeTab?.controller?.reload(),
            onMenu: () => _showMenu(context, state),
          ),

          // Progress bar
          if ((state.activeTab?.progress ?? 0) > 0 &&
              (state.activeTab?.progress ?? 0) < 1)
            LinearProgressIndicator(
              value: state.activeTab?.progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(LightTheme.primary),
            ),

          // Tab bar
          if (state.tabs.length > 1)
            _TabBar(
              tabs: state.tabs,
              activeIndex: state.activeIndex,
              onSwitch: state.switchTab,
              onClose: state.closeTab,
              onAdd: () => state.addTab(),
            ),

          // WebView
          Expanded(
            child: IndexedStack(
              index: state.activeIndex,
              children: state.tabs.map((tab) {
                if (tab.url == 'light://home' || tab.url == 'about:blank') {
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
                  onCreated: (c) => state.setController(tab.id, c),
                  onTitle: (t) => state.updateTab(tab.id, title: t),
                  onUrl: (u) => state.updateTab(tab.id, url: u),
                  onLoadStart: () => state.updateTab(tab.id, isLoading: true),
                  onLoadStop: () =>
                      state.updateTab(tab.id, isLoading: false, progress: 0),
                  onProgress: (p) =>
                      state.updateTab(tab.id, progress: p / 100),
                  adBlock: state.adBlockEnabled,
                  forceDark: state.forceDark,
                );
              }).toList(),
            ),
          ),

          // Bottom nav
          _BottomNav(
            state: state,
            onBack: () => state.activeTab?.controller?.goBack(),
            onForward: () => state.activeTab?.controller?.goForward(),
            onHome: () {
              if (state.activeTab != null) {
                state.updateTab(state.activeTab!.id, url: 'light://home');
              }
            },
            onTabs: () => _showTabs(context, state),
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

  void _showTabs(BuildContext context, BrowserState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LightTheme.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TabSheet(state: state),
    );
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
  final _focus = FocusNode();
  bool _editing = false;

  String _display(String url) => url
      .replaceFirst('https://', '')
      .replaceFirst('http://', '')
      .replaceFirst('www.', '')
      .replaceFirst('light://home', '');

  @override
  void didUpdateWidget(_AddressBar old) {
    super.didUpdateWidget(old);
    if (!_editing) _ctrl.text = _display(widget.tab?.url ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();
    final url = widget.tab?.url ?? '';
    final secure = url.startsWith('https');

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: LightTheme.darkSurface,
      child: Row(children: [
        // Logo
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: LightGradients.brand,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('L', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15,
          ))),
        ),
        const SizedBox(width: 8),

        // URL input
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _editing = true);
              _ctrl.text = widget.tab?.url ?? '';
              _ctrl.selectAll();
              _focus.requestFocus();
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: LightTheme.darkSurface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _editing
                      ? LightTheme.primary.withOpacity(0.5)
                      : LightTheme.darkBorder,
                ),
              ),
              child: Row(children: [
                if (!_editing)
                  Icon(
                    secure ? Icons.lock_outline : Icons.lock_open_outlined,
                    size: 12,
                    color: secure ? LightTheme.accent : LightTheme.warning,
                  ),
                if (!_editing) const SizedBox(width: 4),
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          style: GoogleFonts.spaceGrotesk(
                            color: LightTheme.darkText, fontSize: 13,
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
                        )
                      : Text(
                          _display(url).isEmpty
                              ? 'Search or enter URL'
                              : _display(url),
                          style: GoogleFonts.spaceGrotesk(
                            color: _display(url).isEmpty
                                ? LightTheme.darkTextSec
                                : LightTheme.darkText,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (widget.tab?.isLoading == true)
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LightTheme.primary,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: widget.onReload,
                    child: const Icon(Icons.refresh,
                        size: 14, color: LightTheme.darkTextSec),
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
            child: const Icon(Icons.more_vert,
                color: LightTheme.darkTextSec, size: 18),
          ),
        ),
      ]),
    );
  }
}

// ── WEB TAB ───────────────────────────────────────────────
class _WebTab extends StatelessWidget {
  final BrowserTab tab;
  final Function(InAppWebViewController) onCreated;
  final Function(String) onTitle;
  final Function(String) onUrl;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadStop;
  final Function(int) onProgress;
  final bool adBlock;
  final bool forceDark;

  const _WebTab({
    super.key,
    required this.tab,
    required this.onCreated,
    required this.onTitle,
    required this.onUrl,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onProgress,
    required this.adBlock,
    required this.forceDark,
  });

  @override
  Widget build(BuildContext context) {
    final blocker = AdBlocker();
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: !tab.isPrivate,
        cacheEnabled: !tab.isPrivate,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: true,
        useOnDownloadStart: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
      ),
      onWebViewCreated: onCreated,
      onLoadStart: (c, url) {
        onLoadStart();
        if (url != null) onUrl(url.toString());
      },
      onLoadStop: (c, url) {
        onLoadStop();
        if (url != null) onUrl(url.toString());
        if (forceDark) {
          c.injectCSSCode(source: BrowserState.forceDarkCSS);
        }
      },
      onTitleChanged: (c, title) {
        if (title != null) onTitle(title);
      },
      onProgressChanged: (c, p) => onProgress(p),
      shouldOverrideUrlLoading: (c, action) async {
        final url = action.request.url?.toString() ?? '';
        if (adBlock && blocker.shouldBlock(url)) {
          BlockStats.increment();
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
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
          itemBuilder: (_, i) {
            final tab = tabs[i];
            final active = i == activeIndex;
            return GestureDetector(
              onTap: () => onSwitch(i),
              child: Container(
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
                  Text(
                    tab.title.length > 14
                        ? '${tab.title.substring(0, 14)}…'
                        : tab.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: active
                          ? LightTheme.primary
                          : LightTheme.darkTextSec,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onClose(tab.id),
                    child: const Icon(Icons.close,
                        size: 10, color: LightTheme.darkTextSec),
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
  final VoidCallback onBack, onForward, onHome, onTabs;

  const _BottomNav({
    required this.state,
    required this.onBack,
    required this.onForward,
    required this.onHome,
    required this.onTabs,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: const BoxDecoration(
      color: LightTheme.darkSurface,
      border: Border(top: BorderSide(color: LightTheme.darkBorder)),
    ),
    child: Row(children: [
      _Btn(icon: Icons.arrow_back_ios_new, onTap: onBack),
      _Btn(icon: Icons.arrow_forward_ios, onTap: onForward),
      _Btn(icon: Icons.home_outlined, onTap: onHome),
      _Btn(icon: Icons.refresh, onTap: () => state.activeTab?.controller?.reload()),
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
                    fontSize: 10, fontWeight: FontWeight.w700,
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

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Center(child: Icon(icon, size: 20, color: LightTheme.darkTextSec)),
    ),
  );
}

// ── BROWSER MENU ─────────────────────────────────────────
class _BrowserMenu extends StatelessWidget {
  final BrowserState state;
  const _BrowserMenu({required this.state});

  @override
  Widget build(BuildContext context) => Padding(
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
      _Toggle('🛡️ Ad Block', state.adBlockEnabled,
          (_) => state.toggleAdBlock(), LightTheme.accent),
      _Toggle('🌑 Force Dark', state.forceDark,
          (_) => state.toggleForceDark(), LightTheme.primary),
      _Toggle('🔒 Private Mode', state.isPrivateMode,
          (_) => state.togglePrivateMode(), LightTheme.primary2),
      const SizedBox(height: 8),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onToggle;
  final Color color;

  const _Toggle(this.label, this.value, this.onToggle, this.color);

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    title: Text(label, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkText, fontSize: 14,
    )),
    value: value,
    onChanged: onToggle,
    activeColor: color,
  );
}

// ── TAB SHEET ─────────────────────────────────────────────
class _TabSheet extends StatelessWidget {
  final BrowserState state;
  const _TabSheet({required this.state});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    height: MediaQuery.of(context).size.height * 0.6,
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
          fontSize: 16, fontWeight: FontWeight.w700,
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: state.tabs.length,
          itemBuilder: (_, i) {
            final tab = state.tabs[i];
            final active = i == state.activeIndex;
            return GestureDetector(
              onTap: () {
                state.switchTab(i);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LightTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? LightTheme.primary : LightTheme.darkBorder,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => state.closeTab(tab.id),
                        child: const Icon(Icons.close,
                            size: 14, color: LightTheme.darkTextSec),
                      ),
                    ]),
                    const Spacer(),
                    Text(tab.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: LightTheme.darkText,
                        fontSize: 11, fontWeight: FontWeight.w600,
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
  );
}
