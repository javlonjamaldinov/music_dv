import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pirate Music Box',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontFamily: 'PirateFont',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.amber),
          bodyLarge: TextStyle(
              fontFamily: 'PirateFont', fontSize: 18, color: Colors.amber),
        ),
      ),
      home: const MusicBox(),
    );
  }
}

class MusicBox extends StatefulWidget {
  const MusicBox({super.key});

  @override
  State<MusicBox> createState() => _MusicBoxState();
}

class _MusicBoxState extends State<MusicBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageRotationAnimation;
  bool _isOpen = false;
  bool _isPlaying = false;
  bool _showSongsList = false;
  String? _selectedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AudioCache _audioCache;
  final List<String> _songs = [];
  final List<String> _favorites = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _imageRotationAnimation = Tween<double>(begin: 0.0, end: -2.0 * 3.14)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (!_isPlaying) {
          _controller.stop();
        }
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleMusicBox() async {
    setState(() {
      _isOpen = !_isOpen;
    });

    try {
      if (_isOpen) {
        _controller.repeat();
        if (_selectedFilePath != null) {
          await _audioPlayer.play(DeviceFileSource(_selectedFilePath!));
        }
      } else {
        _controller.stop();
        await _audioPlayer.stop();
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _toggleSongsList() {
    setState(() {
      _showSongsList = !_showSongsList;
    });
  }

  Future<void> _pickMusicFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        if (_selectedFilePath != null) {
          _songs.add(_selectedFilePath!);
        }
      });
    }
  }

  void _addToFavorites(String songPath) {
    setState(() {
      if (!_favorites.contains(songPath)) {
        _favorites.add(songPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text('Pirate Music Box'),
        backgroundColor: Colors.brown.shade700,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.amber),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Help'),
                    content: const Text(
                      'To open or close the music box, press the button. Music will start playing when the box is open.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              child: AnimatedBuilder(
                animation: _imageRotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _imageRotationAnimation.value,
                    child: Image.asset(
                      'assets/images/sailing.png',
                    ),
                  );
                },
              ),
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 225),
                  if (_isPlaying) ...[
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      min: 0.0,
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (value) async {
                        setState(() {
                          _position = Duration(seconds: value.toInt());
                        });
                        await _audioPlayer.seek(_position);
                      },
                    ),
                    Text(
                      '${_position.toString().split('.').first} / ${_duration.toString().split('.').first}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 50),
                  Text(
                    _isOpen ? 'Box is Open' : 'Box is Closed',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _toggleMusicBox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      side: const BorderSide(color: Colors.amber, width: 2),
                    ),
                    child: Text(
                      _isOpen ? 'Close the Box' : 'Open the Box',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 50),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_up_sharp,
                          size: 50,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleSongsList,
                      );
                    },
                  ),
                  if (_showSongsList) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.brown.shade800,
                      child: Column(
                        children: _songs.map((songPath) {
                          return ListTile(
                            title: Text(
                              songPath.split('/').last,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow,
                                      color: Colors.amber),
                                  onPressed: () async {
                                    if (_selectedFilePath != null) {
                                      await _audioPlayer
                                          .play(DeviceFileSource(songPath));
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border,
                                      color: Colors.red),
                                  onPressed: () {
                                    _addToFavorites(songPath);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _pickMusicFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      side: const BorderSide(color: Colors.amber, width: 2),
                    ),
                    child: Text(
                      'Pick a Music File',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (_favorites.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.brown.shade800,
                      child: Column(
                        children: _favorites.map((songPath) {
                          return ListTile(
                            title: Text(
                              songPath.split('/').last,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow,
                                  color: Colors.amber),
                              onPressed: () async {
                                if (_selectedFilePath != null) {
                                  await _audioPlayer
                                      .play(DeviceFileSource(songPath));
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
