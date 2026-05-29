import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/browser_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();
    return Scaffold(
      backgroundColor: LightTheme.darkBg,
      appBar: AppBar(
        backgroundColor: LightTheme.darkSurface,
        title: Text('Settings', style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkText, fontWeight: FontWeight.w700,
        )),
        iconTheme: const IconThemeData(color: LightTheme.darkText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('🔒 Privacy', [
            _toggle('Ad Blocker', 'Block ads & trackers',
                state.adBlockEnabled, (_) => state.toggleAdBlock(),
                LightTheme.accent),
            _toggle('Force Dark Mode', 'Dark theme on all websites',
                state.forceDark, (_) => state.toggleForceDark(),
                LightTheme.primary),
            _toggle('Private Mode', 'No history, no cookies',
                state.isPrivateMode, (_) => state.togglePrivateMode(),
                LightTheme.primary2),
          ]),
          _section('🔍 Search Engine', [
            _radio(context, state, 'Google', 'google'),
            _radio(context, state, 'Bing', 'bing'),
            _radio(context, state, 'DuckDuckGo', 'duckduckgo'),
          ]),
          _section('ℹ️ About', [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Light Browser v1.0.0\n'
                'Fast • Private • Smart 🇮🇳\n\n'
                'Built with Flutter',
                style: GoogleFonts.spaceGrotesk(
                  color: LightTheme.darkTextSec,
                  fontSize: 12, height: 1.6,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkTextSec,
          fontSize: 12, fontWeight: FontWeight.w600,
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

  Widget _toggle(String label, String sub, bool value,
      Function(bool) onChanged, Color color) =>
      SwitchListTile.adaptive(
        title: Text(label, style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkText,
          fontSize: 14, fontWeight: FontWeight.w600,
        )),
        subtitle: Text(sub, style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkTextSec, fontSize: 11,
        )),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      );

  Widget _radio(
      BuildContext context, BrowserState state, String label, String value) =>
      RadioListTile<String>(
        title: Text(label, style: GoogleFonts.spaceGrotesk(
          color: LightTheme.darkText, fontSize: 14,
        )),
        value: value,
        groupValue: state.searchEngine,
        onChanged: (v) => state.setSearchEngine(v!),
        activeColor: LightTheme.primary,
      );
}
