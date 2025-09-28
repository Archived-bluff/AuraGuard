import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyReviewPage extends StatefulWidget {
  @override
  _DailyReviewPageState createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  List<Map<String, String>> faceImages = [];
  List<Map<String, String>> videoUrls = [];
  bool loadingFaces = true;
  bool loadingVideos = true;

  @override
  void initState() {
    super.initState();
    fetchFaces();
    fetchVideos();
  }

  Future<void> fetchFaces() async {
    try {
      final response = await http
          .get(Uri.parse("http://localhost:8000/cloud-faces-unrecognised"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['faces'];
        setState(() {
          faceImages = data
              .map((f) => {
                    "name": f['name'].toString(),
                    "url": f['url'].toString(),
                  })
              .toList();
          loadingFaces = false;
        });
      }
    } catch (e) {
      setState(() => loadingFaces = false);
    }
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http
          .get(Uri.parse("http://localhost:8000/cloud-videos-storage"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['videos'];
        setState(() {
          videoUrls = data
              .map((v) => {
                    "id": v['id'].toString(),
                    "url": v['url'].toString(),
                  })
              .toList();
          loadingVideos = false;
        });
      }
    } catch (e) {
      setState(() => loadingVideos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Review")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Unrecognised Faces",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              loadingFaces
                  ? Center(child: CircularProgressIndicator())
                  : faceImages.isEmpty
                      ? Text("No unrecognised faces")
                      : SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: faceImages.length,
                            itemBuilder: (context, index) {
                              final face = faceImages[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        face['url']!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(face['name']!,
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              SizedBox(height: 20),
              Text("Recent Videos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              loadingVideos
                  ? Center(child: CircularProgressIndicator())
                  : videoUrls.isEmpty
                      ? Text("No videos recorded")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: videoUrls.length,
                          itemBuilder: (context, index) {
                            final video = videoUrls[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: VideoPlayerWidget(url: video['url']!),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Video Player Widget ---
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  VideoPlayerWidget({required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(_controller, allowScrubbing: true),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}
