import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  List<Map<String, String>> recognisedFaces = [];
  List<Map<String, String>> markedFaces = [];
  bool loadingRecognised = true;
  bool loadingMarked = true;

  // User info (you can replace with actual user data)
  final String userName = "John Doe";
  final String userEmail = "john.doe@samsung.com";
  final String userPhone = "+91 98765 43210";

  @override
  void initState() {
    super.initState();
    fetchRecognisedFaces();
    fetchMarkedFaces();
  }

  Future<void> fetchRecognisedFaces() async {
    try {
      final response = await http.get(
          Uri.parse("http://localhost:8000/cloud-faces-folder/recognised"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['faces'];
        setState(() {
          recognisedFaces = data
              .map((f) => {
                    "name": f['name'].toString(),
                    "url": f['url'].toString(),
                  })
              .toList();
          loadingRecognised = false;
        });
      }
    } catch (e) {
      print('Error fetching recognised faces: $e');
      setState(() => loadingRecognised = false);
    }
  }

  Future<void> fetchMarkedFaces() async {
    try {
      final response = await http
          .get(Uri.parse("http://localhost:8000/cloud-faces-folder/marked"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['faces'];
        setState(() {
          markedFaces = data
              .map((f) => {
                    "name": f['name'].toString(),
                    "url": f['url'].toString(),
                  })
              .toList();
          loadingMarked = false;
        });
      }
    } catch (e) {
      print('Error fetching marked faces: $e');
      setState(() => loadingMarked = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      loadingRecognised = true;
      loadingMarked = true;
    });
    await Future.wait([
      fetchRecognisedFaces(),
      fetchMarkedFaces(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    // Profile Picture
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // User Name
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    // User Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // User Phone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: "Recognised",
                        count: recognisedFaces.length,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.warning,
                        label: "Watchlist",
                        count: markedFaces.length,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // Recognised Faces Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Recognised Faces",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Family and friends you trust",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    loadingRecognised
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : recognisedFaces.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.person_off,
                                message: "No recognised faces yet",
                                subtitle:
                                    "Swipe right on faces to add them here",
                              )
                            : _buildFaceGrid(recognisedFaces, Colors.green),
                  ],
                ),
              ),

              Divider(thickness: 1, height: 32),

              // Marked Faces Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Watchlist",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Faces marked for monitoring",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    loadingMarked
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : markedFaces.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.security,
                                message: "No marked faces",
                                subtitle:
                                    "Swipe up on suspicious faces to track them",
                              )
                            : _buildFaceGrid(markedFaces, Colors.orange),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Settings/Options Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.settings,
                      title: "Settings",
                      subtitle: "Manage your preferences",
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.notifications,
                      title: "Notifications",
                      subtitle: "Configure alert preferences",
                      onTap: () {
                        // Navigate to notifications settings
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.privacy_tip,
                      title: "Privacy & Security",
                      subtitle: "Data retention and privacy settings",
                      onTap: () {
                        // Navigate to privacy settings
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.help,
                      title: "Help & Support",
                      subtitle: "Get assistance",
                      onTap: () {
                        // Navigate to help
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.logout,
                      title: "Logout",
                      subtitle: "Sign out of your account",
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceGrid(List<Map<String, String>> faces, Color borderColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // Changed from 0.8 to make squares
      ),
      itemCount: faces.length,
      itemBuilder: (context, index) {
        final face = faces[index];
        return GestureDetector(
          onTap: () {
            _showFaceDetails(context, face, borderColor);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                face['url']!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.grey[600]),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? Colors.deepPurple).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? Colors.deepPurple),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showFaceDetails(
      BuildContext context, Map<String, String> face, Color color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    color == Colors.green ? Icons.check_circle : Icons.warning,
                    color: color,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      face['name']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  face['url']!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text("Remove"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteFace(face['url']!);
                      },
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

  Future<void> _deleteFace(String faceUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/delete-face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'face_url': faceUrl}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove face'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
