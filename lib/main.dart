import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const RetroAmpApp());
}

class RetroAmpApp extends StatelessWidget {
  const RetroAmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroAmp Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E24),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121216),
          elevation: 4,
        ),
      ),
      home: const RetroAmpPlayer(),
    );
  }
}

class RadioStation {
  final String name;
  final String url;
  final String genre;

  RadioStation({required this.name, required this.url, required this.genre});
}

class RetroAmpPlayer extends StatefulWidget {
  const RetroAmpPlayer({super.key});

  @override
  State<RetroAmpPlayer> createState() => _RetroAmpPlayerState();
}

class _RetroAmpPlayerState extends State<RetroAmpPlayer> {
  late AudioPlayer _audioPlayer;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  int _selectedStationIndex = 0;

  final List<RadioStation> _stations = [
    RadioStation(
      name: 'Retro Hits',
      url: 'https://stream.zeno.fm/f3wvbbqmdg8uv',
      genre: '80s & 90s Pop',
    ),
    RadioStation(
      name: 'Rock Classics',
      url: 'https://stream.zeno.fm/0r0xa792kwzuv',
      genre: 'Classic Rock',
    ),
    RadioStation(
      name: 'Jazz & Lounge',
      url: 'https://stream.zeno.fm/64ub8y33q8quv',
      genre: 'Smooth Jazz',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _loadBannerAd();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  Future<void> _playStation(int index) async {
    try {
      setState(() {
        _selectedStationIndex = index;
        _isLoading = true;
      });
      await _audioPlayer.setUrl(_stations[index].url);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yayın yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.audioSource == null) {
        await _playStation(_selectedStationIndex);
      } else {
        await _audioPlayer.play();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStation = _stations[_selectedStationIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RETROAMP',
          style: TextStyle(
            color: Color(0xFFFFBF00),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retro Display Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFBF00), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFBF00).withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentStation.name,
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStation.genre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Equalizer Visual Simulation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(8, (i) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (i * 100)),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: _isPlaying ? (20.0 + (i % 4) * 12) : 6.0,
                              width: 8,
                              decoration: BoxDecoration(
                                color: _isPlaying
                                    ? const Color(0xFF39FF14)
                                    : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 48,
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () {
                          int prevIndex = (_selectedStationIndex - 1 + _stations.length) %
                              _stations.length;
                          _playStation(prevIndex);
                        },
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          backgroundColor: const Color(0xFFFFBF00),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _isLoading ? null : _togglePlayPause,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 40,
                              ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 48,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          int nextIndex = (_selectedStationIndex + 1) % _stations.length;
                          _playStation(nextIndex);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Station List
          Container(
            height: 150,
            color: const Color(0xFF121216),
            child: ListView.builder(
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                final isSelected = index == _selectedStationIndex;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF2A2A35),
                  leading: Icon(
                    Icons.radio,
                    color: isSelected ? const Color(0xFFFFBF00) : Colors.grey,
                  ),
                  title: Text(
                    station.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFBF00) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(station.genre, style: const TextStyle(color: Colors.grey)),
                  onTap: () => _playStation(index),
                );
              },
            ),
          ),
          // AdMob Banner
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
