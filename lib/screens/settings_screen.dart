import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/browser_state.dart';
import '../theme/app_theme.dart';
import '../features/ad_blocker.dart';
import '../features/ai_assistant.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _aiKeyCtrl = TextEditingController(text: AIEngine.apiKey);

  @override
  void dispose() {
    _aiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();

    return Scaffold(
      backgroundColor: LightTheme.darkBg,
      appBar: AppBar(
        backgroundColor: LightTheme.darkSurface,
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkText,
          fontWeight: FontWeight.w700,
        )),
        iconTheme: const IconThemeData(color: LightTheme.darkText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _Section('🤖 AI Assistant', [
            _SettingInput(
              label: 'Claude API Key',
              controller: _aiKeyCtrl,
              hint: 'sk-ant-...',
              onChanged: (v) => AIEngine.apiKey = v,
            ),
            _SettingInfo('Get key from console.anthropic.com — enables AI summarize, translate & chat.'),
          ]),

          _Section('🔒 Privacy & Security', [
            _SettingToggle(
              label: 'Ad Blocker',
              subtitle: '${AdBlocker().blockedCount} domains blocked',
              value: state.adBlockEnabled,
              onToggle: (_) => state.toggleAdBlock(),
              color: LightTheme.accent,
            ),
            _SettingToggle(
              label: 'Force HTTPS',
              subtitle: 'Upgrade insecure connections',
              value: true,
              onToggle: (_) {},
              color: LightTheme.primary,
            ),
            _SettingToggle(
              label: 'Anti-Fingerprint',
              subtitle: 'Randomize browser fingerprint',
              value: true,
              onToggle: (_) {},
              color: LightTheme.warning,
            ),
          ]),

          _Section('🎨 Display', [
            _SettingToggle(
              label: 'Force Dark Mode',
              subtitle: 'Apply dark theme to all websites',
              value: state.forceDark,
              onToggle: (_) => state.toggleForceDark(),
              color: LightTheme.primary,
            ),
            _SettingToggle(
              label: 'Dark Theme (App)',
              subtitle: 'Light Browser UI theme',
              value: state.isDark,
              onToggle: (_) => state.toggleDark(),
              color: LightTheme.primary2,
            ),
          ]),

          _Section('🔍 Search Engine', [
            _SearchEngineSelector(
              current: state.searchEngine,
              onSelected: state.setSearchEngine,
            ),
          ]),

          _Section('ℹ️ About', [
            _SettingInfo('Light Browser v1.0.0\nBuilt with Flutter • Powered by real browser engines\n\n"Sabse tez, sabse safe, sabse smart" 🇮🇳'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(title, style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkTextSec,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        )),
      ),
      Container(
        decoration: BoxDecoration(
          color: LightTheme.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LightTheme.darkBorder),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

class _SettingToggle extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final Function(bool) onToggle;
  final Color color;

  const _SettingToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onToggle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkText, fontSize: 14, fontWeight: FontWeight.w600,
    )),
    subtitle: Text(subtitle, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkTextSec, fontSize: 11,
    )),
    trailing: Switch.adaptive(
      value: value,
      onChanged: onToggle,
      activeColor: color,
    ),
  );
}

class _SettingInput extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SettingInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(
        color: LightTheme.darkText, fontSize: 13, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        style: const TextStyle(color: LightTheme.darkText, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: LightTheme.darkTextSec),
          filled: true,
          fillColor: LightTheme.darkSurface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        obscureText: true,
        onChanged: onChanged,
      ),
    ]),
  );
}

class _SettingInfo extends StatelessWidget {
  final String text;
  const _SettingInfo(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Text(text, style: GoogleFonts.spaceGrotesk(
      color: LightTheme.darkTextSec, fontSize: 12, height: 1.5,
    )),
  );
}

class _SearchEngineSelector extends StatelessWidget {
  final String current;
  final Function(String) onSelected;

  const _SearchEngineSelector({
    required this.current,
    required this.onSelected,
  });

  static const engines = [
    ('google', 'Google', '🔍'),
    ('bing', 'Bing', '🅱️'),
    ('duckduckgo', 'DuckDuckGo', '🦆'),
    ('brave', 'Brave Search', '🦁'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 8,
      children: engines.map((e) {
        final selected = current == e.$1;
        return GestureDetector(
          onTap: () => onSelected(e.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? LightTheme.primary.withOpacity(0.15) : LightTheme.darkSurface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? LightTheme.primary : LightTheme.darkBorder,
              ),
            ),
            child: Text('${e.$3} ${e.$2}', style: GoogleFonts.spaceGrotesk(
              color: selected ? LightTheme.primary : LightTheme.darkTextSec,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
          ),
        );
      }).toList(),
    ),
  );
}
