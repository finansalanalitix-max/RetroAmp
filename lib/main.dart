import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Reklam kütüphanesi

// main() fonksiyonunda AdMob'u başlatıyoruz
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const RetroAmpApp());
}

// Player Sınıfınızın içinde (State yapısında):
class _RetroAmpPlayerState extends State<RetroAmpPlayer> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Google'ın Resmi Test Reklam ID'si (Uygulama onaylanana kadar bu kullanılır)
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // Widget Build Alanı İçerisinde En Alt Kısma Eklenecek Reklam Kutusu:
  Widget _buildAdWidget() {
    if (_isBannerLoaded && _bannerAd != null) {
      return Container(
        color: const Color(0xFF1E1E24),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink(); // Reklam yüklenmediyse yer kaplamaz
  }
}
