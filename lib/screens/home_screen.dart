import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning â˜€ï¸';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon ðŸŒ¤ï¸';
    } else if (hour < 21) {
      _greeting = 'Good Evening ðŸŒ…';
    } else {
      _greeting = 'Good Night ðŸŒ™';
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  final _quickLinks = [
    _QuickLink('Google', 'https://www.google.com', 'ðŸ”'),
    _QuickLink('YouTube', 'https://www.youtube.com', 'â–¶ï¸'),
    _QuickLink('WhatsApp', 'https://web.whatsapp.com', 'ðŸ’¬'),
    _QuickLink('Instagram', 'https://www.instagram.com', 'ðŸ“¸'),
    _QuickLink('Amazon', 'https://www.amazon.in', 'ðŸ›’'),
    _QuickLink('Flipkart', 'https://www.flipkart.com', 'ðŸ›ï¸'),
    _QuickLink('Paytm', 'https://www.paytm.com', 'ðŸ’³'),
    _QuickLink('IRCTC', 'https://www.irctc.co.in', 'ðŸš‚'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BrowserState>();

    return Scaffold(
      backgroundColor: LightTheme.darkBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(children: [
                const SizedBox(height: 60),

                // â”€â”€ LOGO â”€â”€
                _buildLogo(),

                const SizedBox(height: 28),

                // â”€â”€ GREETING â”€â”€
                Text(_greeting, style: GoogleFonts.spaceGrotesk(
                  color: LightTheme.darkTextSec,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),

                const SizedBox(height: 20),

                // â”€â”€ SEARCH BAR â”€â”€
                _buildSearchBar(state),

                const SizedBox(height: 32),

                // â”€â”€ QUICK LINKS â”€â”€
                _buildSectionTitle('Quick Access'),
                const SizedBox(height: 12),
                _buildQuickLinks(),

                const SizedBox(height: 24),

                // â”€â”€ INDIA APPS â”€â”€
                _buildSectionTitle('ðŸ‡®ðŸ‡³ India Essentials'),
                const SizedBox(height: 12),
                _buildIndiaSection(),

                const SizedBox(height: 24),

                // â”€â”€ PRIVACY STATS â”€â”€
                _buildPrivacyCard(),

                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: LightGradients.brand,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: LightTheme.primary.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text('L', style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          )),
        ),
      ),
      const SizedBox(width: 10),
      ShaderMask(
        shaderCallback: (b) => LightGradients.brand.createShader(b),
        child: Text('Light', style: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        )),
      ),
    ],
  );

  Widget _buildSearchBar(BrowserState state) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: LightTheme.darkSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: LightTheme.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search, color: LightTheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.spaceGrotesk(
              color: LightTheme.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search or enter URL...',
              hintStyle: GoogleFonts.spaceGrotesk(
                color: LightTheme.darkTextSec,
                fontSize: 15,
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
        // Voice search icon
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.mic_outlined, color: LightTheme.darkTextSec, size: 18),
        ),
      ]),
    ),
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.spaceGrotesk(
        color: LightTheme.darkTextSec,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      )),
    ),
  );

  Widget _buildQuickLinks() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _quickLinks.length,
      itemBuilder: (ctx, i) {
        final link = _quickLinks[i];
        return GestureDetector(
          onTap: () => widget.onNavigate(link.url),
          child: Column(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: LightTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LightTheme.darkBorder),
              ),
              child: Center(
                child: Text(link.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 6),
            Text(link.name, style: GoogleFonts.spaceGrotesk(
              color: LightTheme.darkTextSec,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
          ]),
        );
      },
    ),
  );

  Widget _buildIndiaSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      _IndiaCard('ðŸ“± UPI Pay', 'https://www.npci.org.in', LightTheme.accent),
      const SizedBox(width: 10),
      _IndiaCard('ðŸ¦ Net Banking', 'https://onlinesbi.sbi.co.in', LightTheme.primary),
      const SizedBox(width: 10),
      _IndiaCard('ðŸ“° News', 'https://news.google.com', LightTheme.warning),
    ].map((w) => Expanded(child: GestureDetector(
      onTap: () {
        if (w is _IndiaCard) widget.onNavigate(w.url);
      },
      child: w,
    ))).toList()),
  );

  Widget _buildPrivacyCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
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
          child: Center(
            child: Icon(Icons.shield_outlined, color: LightTheme.accent, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Light Shield Active', style: GoogleFonts.spaceGrotesk(
              color: LightTheme.darkText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
            Text('Ads, trackers & malware blocked', style: GoogleFonts.spaceGrotesk(
              color: LightTheme.darkTextSec,
              fontSize: 12,
            )),
          ]),
        ),
        Text('ON', style: GoogleFonts.spaceGrotesk(
          color: LightTheme.accent,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        )),
      ]),
    ),
  );
}

class _QuickLink {
  final String name, url, icon;
  const _QuickLink(this.name, this.url, this.icon);
}

class _IndiaCard extends StatelessWidget {
  final String label, url;
  final Color color;
  const _IndiaCard(this.label, this.url, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: LightTheme.darkSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: LightTheme.darkBorder),
    ),
    child: Center(
      child: Text(label, style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      )),
    ),
  );
}
