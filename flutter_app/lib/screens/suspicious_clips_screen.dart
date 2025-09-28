import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SuspiciousClipsScreen extends StatefulWidget {
  const SuspiciousClipsScreen({Key? key}) : super(key: key);

  @override
  State<SuspiciousClipsScreen> createState() => _SuspiciousClipsScreenState();
}

class _SuspiciousClipsScreenState extends State<SuspiciousClipsScreen> {
  // Dummy list of suspicious clips (later this comes from Firebase)
  final List<Map<String, String>> dummyClips = [
    {
      "title": "Suspicious Activity #1",
      "timestamp": "2025-09-03 10:00 AM",
      "videoUrl":
          "https://samplelib.com/lib/preview/mp4/sample-5s.mp4" // free test video
    },
    {
      "title": "Suspicious Activity #2",
      "timestamp": "2025-09-03 02:15 PM",
      "videoUrl":
          "https://samplelib.com/lib/preview/mp4/sample-10s.mp4"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suspicious Clips"),
        backgroundColor: Colors.black87,
      ),
      body: ListView.builder(
        itemCount: dummyClips.length,
        itemBuilder: (context, index) {
          final clip = dummyClips[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(clip["title"]!),
              subtitle: Text("Recorded at: ${clip["timestamp"]}"),
              trailing: const Icon(Icons.play_circle_fill, color: Colors.blue),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(url: clip["videoUrl"]!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Video player screen
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Clip Playback")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
