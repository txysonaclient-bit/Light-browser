import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/browser_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = TextEditingController();
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _greeting = h < 12
        ? 'Good Morning â˜€ï¸'
        : h < 17
            ? 'Good Afternoon ðŸŒ¤ï¸'
            : h < 21
                ? 'Good Evening ðŸŒ…'
                : 'Good Night ðŸŒ™';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  final _links = [
    ['Google', 'https://www.google.com', 'ðŸ”'],
    ['YouTube', 'https://www.youtube.com', 'â–¶ï¸'],
    ['WhatsApp', 'https://web.whatsapp.com', 'ðŸ’¬'],
    ['Instagram', 'https://www.instagram.com', 'ðŸ“¸'],
    ['Amazon', 'https://www.amazon.in', 'ðŸ›’'],
    ['Flipkart', 'https://www.flipkart.com', 'ðŸ›ï¸'],
    ['Paytm', 'https://www.paytm.com', 'ðŸ’³'],
    ['IRCTC', 'https://www.irctc.co.in', 'ðŸš‚'],
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();
    return Scaffold(
      backgroundColor: LightTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 40),

            // Logo
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LightGradients.brand,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: LightTheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('L', style: TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => LightGradients.brand.createShader(b),
                child: Text('Light', style: GoogleFonts.spaceGrotesk(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
              ),
            ]),

            const SizedBox(height: 16),
            Text(_greeting, style: GoogleFonts.spaceGrotesk(
              color: LightTheme.darkTextSec, fontSize: 15,
            )),
            const SizedBox(height: 24),

            // Search bar
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: LightTheme.darkSurface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: LightTheme.darkBorder),
              ),
              child: Row(children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: LightTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.spaceGrotesk(
                      color: LightTheme.darkText, fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search or enter URL...',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: LightTheme.darkTextSec,
                      ),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        widget.onNavigate(state.resolveUrl(v));
                      }
                    },
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // Quick links
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick Access', style: GoogleFonts.spaceGrotesk(
                color: LightTheme.darkTextSec, fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _links.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => widget.onNavigate(_links[i][1]),
                child: Column(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: LightTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LightTheme.darkBorder),
                    ),
                    child: Center(child: Text(_links[i][2],
                      style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(height: 6),
                  Text(_links[i][0], style: GoogleFonts.spaceGrotesk(
                    color: LightTheme.darkTextSec, fontSize: 11,
                  )),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            // Shield card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LightGradients.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LightTheme.darkBorder),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: LightTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(
                    Icons.shield_outlined,
                    color: LightTheme.accent, size: 20,
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Light Shield Active', style: GoogleFonts.spaceGrotesk(
                      color: LightTheme.darkText,
                      fontWeight: FontWeight.w700, fontSize: 14,
                    )),
                    Text('Ads & trackers blocked', style: GoogleFonts.spaceGrotesk(
                      color: LightTheme.darkTextSec, fontSize: 12,
                    )),
                  ],
                )),
                Text('ON', style: GoogleFonts.spaceGrotesk(
                  color: LightTheme.accent,
                  fontWeight: FontWeight.w800, fontSize: 13,
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
