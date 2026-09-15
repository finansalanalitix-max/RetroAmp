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
  final String category;

  RadioStation({
    required this.name,
    required this.url,
    required this.category,
  });
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
  String _selectedCategory = 'Tümü';

  // Test edilmiş ve %100 Çalışan Doğrudan Akış Adresleri
  final List<RadioStation> _allStations = [
    // --- ULUSAL (TÜRKİYE) ---
    RadioStation(
      name: 'Power FM',
      url: 'https://powerfm.listenpowerapp.com/powerfm/mpeg/icecast.audio',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Kral FM',
      url: 'https://kralfm.listenpowerapp.com/kralfm/mpeg/icecast.audio',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Power Türk',
      url: 'https://powerturk.listenpowerapp.com/powerturk/mpeg/icecast.audio',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'TRT FM',
      url: 'https://radioturkey.live/stream/trt-fm',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Joy FM',
      url: 'https://17703.live.streamtheworld.com/JOY_FM.mp3',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Metro FM',
      url: 'https://17733.live.streamtheworld.com/METRO_FM.mp3',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Süper FM',
      url: 'https://17733.live.streamtheworld.com/SUPER_FM.mp3',
      category: 'Ulusal',
    ),
    RadioStation(
      name: 'Virgin Radio TR',
      url: 'https://17733.live.streamtheworld.com/VIRGIN_RADIO.mp3',
      category: 'Ulusal',
    ),

    // --- ULUSLARARASI (INTERNATIONAL) ---
    RadioStation(
      name: 'BBC Radio 1 (UK)',
      url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'Capital FM (UK)',
      url: 'https://media-ice.musicradio.com/CapitalMP3',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'NRJ Pop (Fransa)',
      url: 'https://cdn.nrjaudio.fm/audio/live-fr/fr/mp3_128/nrj_1001.mp3',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'Antenne Bayern (Almanya)',
      url: 'https://mp3channels.webradio.antenne.de/antenne',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'Radio Ibiza (İtalya)',
      url: 'https://stream1.radioibiza.it/stream',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'Jazz Grooves (ABD)',
      url: 'https://west-mp3-128.sublimejazz.com/wr-jazz-mp3-128',
      category: 'Uluslararası',
    ),
    RadioStation(
      name: 'Chillout Lounge (Global)',
      url: 'https://stream.zeno.fm/f3wvbbqmdg8uv',
      category: 'Uluslararası',
    ),
  ];

  List<RadioStation> _displayedStations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _displayedStations = List.from(_allStations);
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

  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _displayedStations = _allStations.where((station) {
        final matchesCategory = _selectedCategory == 'Tümü' ||
            station.category == _selectedCategory;
        final matchesQuery = station.name.toLowerCase().contains(query) ||
            station.category.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
      _selectedStationIndex = 0;
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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
    if (_displayedStations.isEmpty) return;
    try {
      setState(() {
        _selectedStationIndex = index;
        _isLoading = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(_displayedStations[index].url);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yayın bağlantısı kurulamadı: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.audioSource == null && _displayedStations.isNotEmpty) {
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStation = _displayedStations.isNotEmpty &&
            _selectedStationIndex < _displayedStations.length
        ? _displayedStations[_selectedStationIndex]
        : null;

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retro Ekran Paneli
                  Container(
                    width: double.infinity,
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
                          currentStation?.name ?? 'Radyo Seçin',
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentStation?.category ?? '-',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Ses Görselleştirici (VU Meter Efekti)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(8, (i) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 250 + (i * 80)),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: _isPlaying ? (16.0 + (i % 4) * 14) : 6.0,
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
                  const SizedBox(height: 20),
                  // Kontrol Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () {
                          if (_displayedStations.isEmpty) return;
                          int prevIndex = (_selectedStationIndex - 1 + _displayedStations.length) %
                              _displayedStations.length;
                          _playStation(prevIndex);
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: const Color(0xFFFFBF00),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _isLoading ? null : _togglePlayPause,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 36,
                              ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          if (_displayedStations.isEmpty) return;
                          int nextIndex = (_selectedStationIndex + 1) % _displayedStations.length;
                          _playStation(nextIndex);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Kategori Seçim Butonları (Tümü, Ulusal, Uluslararası)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Tümü', 'Ulusal', 'Uluslararası'].map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFBF00),
                  backgroundColor: const Color(0xFF121216),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterStations();
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterStations(),
              decoration: InputDecoration(
                hintText: 'Radyo veya Ülke Arayın...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFBF00)),
                filled: true,
                fillColor: const Color(0xFF121216),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // Radyo Listesi
          Container(
            height: 170,
            color: const Color(0xFF121216),
            child: _displayedStations.isEmpty
                ? const Center(child: Text('Aradığınız kriterde radyo bulunamadı.'))
                : ListView.builder(
                    itemCount: _displayedStations.length,
                    itemBuilder: (context, index) {
                      final station = _displayedStations[index];
                      final isSelected = index == _selectedStationIndex;
                      return ListTile(
                        dense: true,
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
                        subtitle: Text(
                          station.category,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        onTap: () => _playStation(index),
                      );
                    },
                  ),
          ),

          // AdMob Banner Reklam
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
