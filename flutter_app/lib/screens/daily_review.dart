import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class DailyReviewPage extends StatefulWidget {
  @override
  _DailyReviewPageState createState() => _DailyReviewPageState();
}

class _DailyReviewPageState extends State<DailyReviewPage> {
  List<Map<String, String>> faceImages = [];
  List<Map<String, String>> videoUrls = [];
  bool loadingFaces = true;
  bool loadingVideos = true;
  int currentIndex = 0;

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

  Future<void> handleSwipe(String direction, String faceUrl) async {
    String endpoint = '';
    Map<String, dynamic> body = {'face_url': faceUrl};

    if (direction == 'right') {
      endpoint = 'http://localhost:8000/move-face';
      body['target_folder'] = 'recognised';
    } else if (direction == 'up') {
      endpoint = 'http://localhost:8000/move-face';
      body['target_folder'] = 'marked';
    } else if (direction == 'left') {
      endpoint = 'http://localhost:8000/delete-face';
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (currentIndex < faceImages.length) {
            currentIndex++;
          }
        });

        String message = direction == 'right'
            ? '✓ Marked as Recognised'
            : direction == 'up'
                ? '⚠ Added to Watchlist'
                : '✗ Deleted';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 1),
            backgroundColor: direction == 'right'
                ? Colors.green
                : direction == 'up'
                    ? Colors.orange
                    : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Review"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unrecognised Faces",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              loadingFaces
                  ? Center(child: CircularProgressIndicator())
                  : faceImages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 64, color: Colors.green),
                                SizedBox(height: 16),
                                Text(
                                  "No unrecognised faces",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : currentIndex >= faceImages.length
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.done_all,
                                        size: 64, color: Colors.green),
                                    SizedBox(height: 16),
                                    Text(
                                      "All faces reviewed!",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          currentIndex = 0;
                                        });
                                        fetchFaces();
                                      },
                                      child: Text("Refresh"),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SwipeableCard(
                              face: faceImages[currentIndex],
                              onSwipe: handleSwipe,
                              totalCards: faceImages.length,
                              currentCard: currentIndex + 1,
                            ),
              SizedBox(height: 30),
              Text(
                "Recent Videos",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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

// --- Swipeable Card Widget ---
class SwipeableCard extends StatefulWidget {
  final Map<String, String> face;
  final Function(String direction, String faceUrl) onSwipe;
  final int totalCards;
  final int currentCard;

  SwipeableCard({
    required this.face,
    required this.onSwipe,
    required this.totalCards,
    required this.currentCard,
  });

  @override
  _SwipeableCardState createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final threshold = 100.0;
    String? direction;

    if (_dragOffset.dx.abs() > _dragOffset.dy.abs()) {
      // Horizontal swipe
      if (_dragOffset.dx > threshold) {
        direction = 'right'; // Recognised
      } else if (_dragOffset.dx < -threshold) {
        direction = 'left'; // Delete
      }
    } else {
      // Vertical swipe
      if (_dragOffset.dy < -threshold) {
        direction = 'up'; // Marked
      }
    }

    if (direction != null) {
      _animateCardAway(direction);
    } else {
      // Reset position
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _animateCardAway(String direction) {
    Offset targetOffset;
    if (direction == 'right') {
      targetOffset = Offset(500, 0);
    } else if (direction == 'left') {
      targetOffset = Offset(-500, 0);
    } else {
      targetOffset = Offset(0, -500);
    }

    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animation.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });

    _animationController.forward().then((_) {
      widget.onSwipe(direction, widget.face['url']!);
      _animationController.reset();
      setState(() {
        _dragOffset = Offset.zero;
      });
    });
  }

  Color _getOverlayColor() {
    if (_dragOffset.dx.abs() > _dragOffset.dy.abs()) {
      if (_dragOffset.dx > 50) return Colors.green.withOpacity(0.3);
      if (_dragOffset.dx < -50) return Colors.red.withOpacity(0.3);
    } else {
      if (_dragOffset.dy < -50) return Colors.orange.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  String _getOverlayText() {
    if (_dragOffset.dx.abs() > _dragOffset.dy.abs()) {
      if (_dragOffset.dx > 50) return 'RECOGNISED';
      if (_dragOffset.dx < -50) return 'DELETE';
    } else {
      if (_dragOffset.dy < -50) return 'WATCHLIST';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = _dragOffset.dx / screenWidth * 0.4;

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.currentCard} / ${widget.totalCards}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 500,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Instructions card (background)
              if (_dragOffset.dx == 0 && _dragOffset.dy == 0)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      elevation: 2,
                      color: Colors.grey[100],
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swipe, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Swipe to categorize',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 24),
                              _buildInstruction(Icons.arrow_forward, 'Right',
                                  'Recognised', Colors.green),
                              SizedBox(height: 12),
                              _buildInstruction(Icons.arrow_upward, 'Up',
                                  'Watchlist', Colors.orange),
                              SizedBox(height: 12),
                              _buildInstruction(Icons.arrow_back, 'Left',
                                  'Delete', Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Main swipeable card
              Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: rotation,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: screenWidth * 0.85,
                      height: 450,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                widget.face['url']!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(Icons.error, size: 64),
                                  );
                                },
                              ),
                            ),
                            // Overlay color and text
                            if (_getOverlayText().isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: _getOverlayColor(),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _getOverlayText(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // Face name at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  widget.face['name']!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(
      IconData icon, String direction, String action, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 8),
        Text(
          '$direction: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          action,
          style: TextStyle(fontSize: 16, color: color),
        ),
      ],
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
