import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform, ); // Make sure google-services.json / plist is added
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swipe Prototype',
      theme: ThemeData.dark(),
      home: const SwipeScreen(),
    );
  }
}

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  late MatchEngine _matchEngine;
  final List<SwipeItem> _swipeItems = [];

  @override
  void initState() {
    super.initState();

    // Dummy media list (images + video)
    final List<Map<String, String>> mediaList = [
      {"type": "image", "url": "https://i.pravatar.cc/300?img=11"},
      {"type": "image", "url": "https://i.pravatar.cc/300?img=22"},
      {
        "type": "video",
        "url": "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"
      },
      {"type": "image", "url": "https://i.pravatar.cc/300?img=33"},
    ];

    for (final media in mediaList) {
      _swipeItems.add(
        SwipeItem(
          content: media,
          likeAction: () => _showSnack("Categorized as Recognised ✅"),
          nopeAction: () => _showSnack("Categorized as Unrecognised 🚨"),
          superlikeAction: () => _showSnack("Flagged for Monitoring 🔍"),
        ),
      );
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Security Review"),
        centerTitle: true,
      ),
      body: Center(
        child: SwipeCards(
          matchEngine: _matchEngine,
          itemBuilder: (context, index) {
            final media = _swipeItems[index].content as Map<String, String>;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (media["type"] == "image")
                    Image.network(
                      media["url"]!,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  else if (media["type"] == "video")
                    VideoPlayerWidget(url: media["url"]!),
                  const SizedBox(height: 20),
                  Text("Media ${index + 1}", style: const TextStyle(fontSize: 22)),
                ],
              ),
            );
          },
          onStackFinished: () => _showSnack("Daily review complete. All media processed."),
          upSwipeAllowed: true,
          fillSpace: true,
        ),
      ),
    );
  }
}

/// Video Player Widget
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isReady = true);
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isReady
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
