import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const RetroAmpApp());
}

class RetroAmpApp extends StatelessWidget {
  const RetroAmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetroAmp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E24),
      ),
      home: const RetroAmpPlayer(),
    );
  }
}

class RetroAmpPlayer extends StatefulWidget {
  const RetroAmpPlayer({super.key});

  @override
  State<RetroAmpPlayer> createState() => _RetroAmpPlayerState();
}

class _RetroAmpPlayerState extends State<RetroAmpPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<dynamic> _stations = [];
  int _currentIndex = -1;
  bool _isLoading = false;
  String _statusText = "RETROAMP READY - SELECT A STATION";

  @override
  void initState() {
    super.initState();
    _fetchStations('Turkey');
  }

  Future<void> _fetchStations(String country) async {
    setState(() {
      _isLoading = true;
      _statusText = "SEARCHING STATIONS...";
    });

    try {
      final response = await http.get(
        Uri.parse('https://de1.api.radio-browser.info/json/stations/bycountryexact/$country?limit=30'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _stations = data.where((s) => (s['url_resolved'] as String).isNotEmpty).toList();
          _isLoading = false;
          _statusText = "LOADED ${_stations.length} STATIONS";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = "CONNECTION ERROR";
      });
    }
  }

  Future<void> _playStation(int index) async {
    if (index < 0 || index >= _stations.length) return;

    final station = _stations[index];
    final String url = station['url_resolved'];

    setState(() {
      _currentIndex = index;
      _statusText = "BUFFERING: ${station['name'].toString().toUpperCase()}";
    });

    try {
      await _audioPlayer.setUrl(url);
      _audioPlayer.play();
      setState(() {
        _statusText = "PLAYING: ${station['name'].toString().toUpperCase()}";
      });
    } catch (e) {
      setState(() {
        _statusText = "STREAM ERROR - TRY ANOTHER";
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2C34),
        title: const Text(
          '⚡ RETROAMP HI-FI TUNER',
          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B1E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade700, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.amber.shade900.withOpacity(0.3), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("STEREO", style: TextStyle(color: Colors.amber, fontSize: 10, fontFamily: 'monospace')),
                    Text(_audioPlayer.playing ? "● LIVE" : "○ STOPPED", style: TextStyle(color: _audioPlayer.playing ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(16, (index) {
                    return Container(
                      width: 8,
                      height: _audioPlayer.playing ? (15 + (index * 7) % 25).toDouble() : 4,
                      color: index > 12 ? Colors.redAccent : (index > 8 ? Colors.orangeAccent : Colors.greenAccent),
                    );
                  }),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.amber),
                  onPressed: () => _playStation(_currentIndex - 1),
                ),
                StreamBuilder<bool>(
                  stream: _audioPlayer.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return FloatingActionButton(
                      backgroundColor: Colors.amber.shade800,
                      child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                      onPressed: () {
                        if (isPlaying) {
                          _audioPlayer.pause();
                        } else if (_currentIndex != -1) {
                          _audioPlayer.play();
                        }
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.redAccent),
                  onPressed: () => _audioPlayer.stop(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.amber),
                  onPressed: () => _playStation(_currentIndex + 1),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.amber, thickness: 0.5),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text("STATION LIST", style: TextStyle(color: Colors.amber, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : ListView.builder(
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      final isSelected = index == _currentIndex;

                      return ListTile(
                        dense: true,
                        tileColor: isSelected ? Colors.amber.withOpacity(0.15) : null,
                        title: Text(
                          station['name'].toString().trim(),
                          style: TextStyle(
                            color: isSelected ? Colors.amberAccent : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'monospace',
                          ),
                        ),
                        subtitle: Text(
                          "${station['tags'] ?? 'Radio'} • ${station['bitrate'] ?? '128'}kbps",
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        trailing: isSelected && _audioPlayer.playing
                            ? const Icon(Icons.volume_up, color: Colors.amber, size: 18)
                            : null,
                        onTap: () => _playStation(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
