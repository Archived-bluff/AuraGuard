import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuspiciousActivityPage extends StatefulWidget {
  @override
  _SuspiciousActivityPageState createState() => _SuspiciousActivityPageState();
}

class _SuspiciousActivityPageState extends State<SuspiciousActivityPage> {
  bool isMonitoring = false;
  bool isLoading = false;
  String statusMessage = "Ready to start monitoring";

  final String baseUrl = "http://localhost:8000";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AuraGuard - Suspicious Activity"),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // ADD THIS - makes the whole page scrollable
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Samsung Security Monitor",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "AI-Powered Face Detection & Recording",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Camera Window Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isMonitoring ? Colors.red[50] : Colors.grey[100],
                border: Border.all(
                  color: isMonitoring ? Colors.red[300]! : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    isMonitoring ? Icons.videocam : Icons.videocam_off,
                    size: 64,
                    color: isMonitoring ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isMonitoring
                        ? "CAMERA WINDOW ACTIVE"
                        : "CAMERA WINDOW INACTIVE",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMonitoring ? Colors.red[700] : Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    isMonitoring
                        ? "Check your desktop for the OpenCV camera window.\nYou'll see green rectangles around detected faces."
                        : "Click 'Start Monitoring' to open camera window on your desktop.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMonitoring ? Colors.red[600] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Status Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMonitoring ? Colors.green[50] : Colors.blue[50],
                border: Border.all(
                  color: isMonitoring ? Colors.green[300]! : Colors.blue[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isMonitoring ? "MONITORING ACTIVE" : "MONITORING READY",
                    style: TextStyle(
                      color:
                          isMonitoring ? Colors.green[700] : Colors.blue[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    statusMessage,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (isMonitoring) ...[
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFeatureChip(
                            "Face Detection", Icons.face, Colors.green),
                        _buildFeatureChip(
                            "Auto Record (10s)", Icons.videocam, Colors.orange),
                        _buildFeatureChip(
                            "Cloud Storage", Icons.cloud, Colors.blue),
                        _buildFeatureChip("Face Recognition", Icons.psychology,
                            Colors.purple),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 30),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : (isMonitoring ? _stopMonitoring : _startMonitoring),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isMonitoring ? Colors.red[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isMonitoring ? Icons.stop : Icons.play_arrow,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  isMonitoring ? "STOP" : "START",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (isMonitoring) ...[
                  SizedBox(width: 16),
                  Container(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _analyzeFaces,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 20),
                          Text("Analyze", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 20),

            // Instructions
            if (!isMonitoring)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How it works:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "1. Click 'START' to open camera window\n2. Position yourself in camera view\n3. After 10 seconds of face detection, recording begins\n4. Snapshot + Video automatically uploaded to cloud",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ... rest of your methods remain the same
  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMonitoring() async {
    setState(() {
      isLoading = true;
      statusMessage = "Starting monitoring system...";
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/start-monitoring"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          isMonitoring = true;
          isLoading = false;
          statusMessage =
              "Monitoring active - Check desktop for camera window with green face rectangles";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Monitoring started! Look for the OpenCV camera window on your desktop."),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception('Failed to start monitoring: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = "Failed to start monitoring";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _stopMonitoring() async {
    setState(() {
      isLoading = true;
      statusMessage = "Stopping monitoring...";
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/stop-monitoring"),
        headers: {'Content-Type': 'application/json'},
      );

      setState(() {
        isMonitoring = false;
        isLoading = false;
        statusMessage = "Monitoring stopped - All recordings uploaded to cloud";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Monitoring stopped. Camera window closed."),
          backgroundColor: Colors.orange[600],
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = "Error stopping monitoring";
      });
    }
  }

  Future<void> _analyzeFaces() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/analyze-faces"),
        headers: {'Content-Type': 'application/json'},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Face analysis completed! Check backend console for results."),
          backgroundColor: Colors.purple[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Analysis failed: $e"),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
