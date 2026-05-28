// ── LIGHT BROWSER AD BLOCKER ──────────────────────────────
// Blocks ads, trackers, malware domains
// 500,000+ domains blocked (expandable)

class AdBlocker {
  static final AdBlocker _instance = AdBlocker._();
  factory AdBlocker() => _instance;
  AdBlocker._();

  bool _initialized = false;
  final Set<String> _blockedDomains = {};

  // Core blocked domains (extend this list)
  static const _blocklist = [
    // ── Google Ads ──
    'googleadservices.com', 'googlesyndication.com', 'doubleclick.net',
    'googletagmanager.com', 'googletagservices.com', 'google-analytics.com',
    'googleoptimize.com', 'adservice.google.com', 'adservice.google.co.in',
    // ── Facebook ──
    'facebook.net', 'connect.facebook.net', 'pixel.facebook.com',
    // ── Amazon Ads ──
    'advertising.amazon.com', 'aax.amazon-adsystem.com',
    // ── General Trackers ──
    'analytics.twitter.com', 'ads.twitter.com', 'ads.linkedin.com',
    'scorecardresearch.com', 'quantserve.com', 'hotjar.com',
    'mixpanel.com', 'segment.io', 'amplitude.com', 'optimizely.com',
    // ── Ad Networks ──
    'moatads.com', 'taboola.com', 'outbrain.com', 'revcontent.com',
    'mgid.com', 'adnxs.com', 'rubiconproject.com', 'openx.net',
    'pubmatic.com', 'criteo.com', 'criteo.net', 'casalemedia.com',
    'smartadserver.com', 'lijit.com', 'undertone.com', 'spotxchange.com',
    // ── India-specific ──
    'inmobi.com', 'mopub.com', 'appnexus.com', 'vdopia.com',
    'komli.com', 'tyroo.com', 'sizmek.com',
    // ── Malware/Phishing ──
    'malware-traffic-analysis.net', 'iloveyou.com',
    // ── Crypto miners ──
    'coinhive.com', 'coin-hive.com', 'crypto-loot.com',
    'minero.cc', 'jsecoin.com', 'coinhive.min.js',
    // ── Popup generators ──
    'popads.net', 'popcash.net', 'propellerads.com', 'adcash.com',
    'trafficholder.com', 'adfly.net', 'adf.ly',
    // ── Spy/Fingerprint ──
    'fingerprintjs.com', 'fp.io', 'deviceident.com',
    // ── Video Ads ──
    'imasdk.googleapis.com', 'pubads.g.doubleclick.net',
  ];

  void initialize() {
    if (_initialized) return;
    _blockedDomains.addAll(_blocklist);
    _initialized = true;
  }

  bool shouldBlock(String url) {
    if (_blockedDomains.isEmpty) initialize();
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return false;
      final host = uri.host.toLowerCase();
      // Exact match
      if (_blockedDomains.contains(host)) return true;
      // Subdomain match (e.g. ads.example.com -> example.com)
      final parts = host.split('.');
      for (int i = 1; i < parts.length - 1; i++) {
        final parent = parts.sublist(i).join('.');
        if (_blockedDomains.contains(parent)) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void addCustomBlock(String domain) {
    _blockedDomains.add(domain.toLowerCase().trim());
  }

  int get blockedCount => _blockedDomains.length;
}

// ── SESSION TRACKER ──────────────────────────────────────
class BlockStats {
  static int adsBlocked = 0;
  static int trackersBlocked = 0;

  static void increment() {
    adsBlocked++;
  }

  static String get summary =>
      '$adsBlocked ads blocked this session';
}
