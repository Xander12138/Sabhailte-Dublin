import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sabhailte_dubin/core/constant.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:sabhailte_dubin/features/auth/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> newsItems = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _locationController = TextEditingController();
  String? _imageBase64;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> fetchNews() async {
    try {
      final response =
          await http.get(Uri.parse('$BASE_URL/news'));
      if (response.statusCode == 200) {
        // Decode response as a Map
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> newsData = data["news"]; // Extract the "news" array
        final List<Map<String, dynamic>> fetchedNews = newsData.map((news) {
          // Parse the JSON string for coordinates
          final locationData = jsonDecode(news[6]) as Map<String, dynamic>;
          return {
            "id": news[0],
            "author": news[1],
            "imageBase64": news[2], // Base64 image data
            "title": news[3],
            "description": news[4],
            "time": _formatDateTime(news[5]),
            "location": _formatLocation(locationData['latitude'], locationData['longitude']),
            "views": news[7]?.toString() ?? "0",
            "comments": "0",
            "likes": "0",
            "reactions": {},
            "userReaction": null,
          };
        }).toList();

        setState(() {
          newsItems = fetchedNews;
        });

        // Fetch reactions for each news item
        for (var news in newsItems) {
          await fetchReactions(news["id"]);
        }
      } else {
        throw Exception('Failed to fetch news. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching news: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchReactions(String newsId) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/news/$newsId/reactions')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // Find the news item and update its reactions
          for (int i = 0; i < newsItems.length; i++) {
            if (newsItems[i]["id"] == newsId) {
              newsItems[i]["reactions"] = data["counts"];

              // Get the user from AuthProvider instead of directly using Firebase UID
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              // Use the internal user_id if available, otherwise fall back to Firebase UID
              String currentUserId = authProvider.user?.userId ??
                                    (FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user");

              final reactions = data["reactions"] as List;
              for (var reaction in reactions) {
                if (reaction["user_id"] == currentUserId) {
                  newsItems[i]["userReaction"] = reaction["reaction_type"];
                  break;
                }
              }

              break;
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching reactions: $e');
    }
  }

  Future<void> reactToNews(String newsId, String reactionType) async {
    try {
      // Get the user from AuthProvider instead of directly using Firebase UID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Use the internal user_id if available, otherwise fall back to Firebase UID
      String currentUserId = authProvider.user?.userId ??
                             (FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user");

      final response = await http.post(
        Uri.parse('$BASE_URL/news/$newsId/reactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': currentUserId,
          'reaction_type': reactionType,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh reactions for this news item
        await fetchReactions(newsId);
      } else {
        throw Exception('Failed to react to news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error reacting to news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reacting to news: ${e.toString()}')),
      );
    }
  }

  Future<void> deleteReaction(String newsId) async {
    try {
      // Get the user from AuthProvider instead of directly using Firebase UID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Use the internal user_id if available, otherwise fall back to Firebase UID
      String currentUserId = authProvider.user?.userId ??
                             (FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user");

      final response = await http.delete(
        Uri.parse('$BASE_URL/news/$newsId/reactions/$currentUserId'),
      );

      if (response.statusCode == 200) {
        // Refresh reactions for this news item
        await fetchReactions(newsId);
      } else {
        throw Exception('Failed to delete reaction: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting reaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reaction: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        // Convert to base64 and verify it's properly formatted
        final base64String = base64Encode(bytes);

        // Validate that we have a proper base64 string (not a URL)
        if (base64String.startsWith('http')) {
          throw Exception('Invalid image format: URL detected instead of Base64');
        }

        // Using mounted check before setState to avoid issues with async operations
        if (mounted) {
          setState(() {
            _imageBase64 = base64String;
          });
        }

        print('Image encoded successfully: ${base64String.length} bytes');
        // Only print a small prefix of the base64 string for debugging
        if (base64String.length > 30) {
          print('Base64 preview: ${base64String.substring(0, 30)}...');
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitNewsForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    // Validate the Base64 string once more
    try {
      // Just try to decode it to see if it's valid Base64
      base64Decode(_imageBase64!);
    } catch (e) {
      print('Invalid Base64 image data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The selected image is not in a valid format')),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // Get the current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user";

      // Use the string user ID as is, without converting to integer
      String userId = authProvider.user?.userId ??
                       (firebaseUid.startsWith('user_') ? firebaseUid : "user_$firebaseUid");

      // Create location JSON
      // Default to Dublin City coordinates if no location is specified
      Map<String, dynamic> locationData = {
        'latitude': 53.349805,
        'longitude': -6.26031,
      };

      // If location is specified, use custom coordinates
      if (_locationController.text.isNotEmpty) {
        if (_locationController.text.toLowerCase().contains('north dublin')) {
          locationData = {
            'latitude': 53.4,
            'longitude': -6.15,
          };
        } else if (_locationController.text.toLowerCase().contains('south dublin')) {
          locationData = {
            'latitude': 53.25,
            'longitude': -6.15,
          };
        }
      }

      final location = jsonEncode(locationData);

      print('Submitting news with image size: ${_imageBase64!.length} bytes');

      // Submit the form data with string author_id
      final response = await http.post(
        Uri.parse('$BASE_URL/news'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': userId, // Send as string in format "user_[uuid]"
          'cover_link': _imageBase64,
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'location': location,
          'views': 0,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear the form
        _titleController.clear();
        _subtitleController.clear();
        _locationController.clear();
        setState(() {
          _imageBase64 = null;
        });

        // Refresh the news list
        fetchNews();

        // Close the dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('News added successfully')),
        );
      } else {
        throw Exception('Failed to add news: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding news: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding news: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAddNewsForm() {
    // Use StatefulBuilder to manage state within the dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Add News',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker with local setState
                  InkWell(
                    onTap: () async {
                      // Use a local image picker that updates dialog state
                      try {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          maxHeight: 800,
                          imageQuality: 85,
                        );

                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          final base64String = base64Encode(bytes);

                          // Update both the parent state and dialog state
                          this.setState(() {
                            _imageBase64 = base64String;
                          });

                          // Update dialog state to refresh UI immediately
                          setState(() {
                            // This empty setState will trigger a rebuild with the new _imageBase64
                          });

                          print('Image encoded: ${base64String.length} bytes');
                        }
                      } catch (e) {
                        print('Error picking image in dialog: $e');
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Error picking image: ${e.toString()}')),
                        );
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _imageBase64 != null
                          ? Builder(
                              builder: (context) {
                                try {
                                  return Image.memory(
                                    base64Decode(_imageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error displaying image preview: $error');
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                                          SizedBox(height: 8),
                                          Text(
                                            'Invalid image format',
                                            style: TextStyle(color: Colors.red[400]),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } catch (e) {
                                  print('Error decoding image for preview: $e');
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
                                      SizedBox(height: 8),
                                      Text(
                                        'Invalid Base64 image',
                                        style: TextStyle(color: Colors.red[400]),
                                      ),
                                    ],
                                  );
                                }
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to select an image',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Subtitle field
                  TextFormField(
                    controller: _subtitleController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Location field
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintText: 'Dublin City Center, North Dublin, South Dublin, etc.',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitNewsForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Bí sábháilte.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: newsItems.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : ListView.builder(
                    itemCount: newsItems.length,
                    itemBuilder: (context, index) {
                      final news = newsItems[index];
                      return _buildNewsCard(context, news);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNewsForm,
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add News',
      ),
    );
  }

  // Widget to build each news card
  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> news) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // News image with fallback
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildImageFromBase64(news["imageBase64"]),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  news["title"],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Description
                Text(
                  news["description"],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Metadata (time, location, views, comments, likes)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${news["time"]} · ${news["location"]}",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      news["views"],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      news["comments"],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Like icon with interaction
                    InkWell(
                      onTap: () {
                        if (news["userReaction"] == "like") {
                          deleteReaction(news["id"]);
                        } else {
                          reactToNews(news["id"], "like");
                        }
                      },
                      child: Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: news["userReaction"] == "like"
                            ? Colors.blue
                            : Colors.grey[500],
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      (news["reactions"]["like"] ?? 0).toString(),
                      style: TextStyle(
                        color: news["userReaction"] == "like"
                            ? Colors.blue
                            : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Reaction buttons row
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReactionButton(
                      context,
                      news,
                      "like",
                      Icons.thumb_up,
                      "Like",
                    ),
                    _buildReactionButton(
                      context,
                      news,
                      "love",
                      Icons.favorite,
                      "Love",
                    ),
                    _buildReactionButton(
                      context,
                      news,
                      "sad",
                      Icons.sentiment_dissatisfied,
                      "Sad",
                    ),
                    _buildReactionButton(
                      context,
                      news,
                      "angry",
                      Icons.sentiment_very_dissatisfied,
                      "Angry",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build reaction buttons
  Widget _buildReactionButton(
    BuildContext context,
    Map<String, dynamic> news,
    String reactionType,
    IconData icon,
    String label,
  ) {
    bool isSelected = news["userReaction"] == reactionType;
    return InkWell(
      onTap: () {
        if (isSelected) {
          deleteReaction(news["id"]);
        } else {
          reactToNews(news["id"], reactionType);
        }
      },
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue : Colors.grey[500],
          ),
          Text(
            "${news["reactions"][reactionType] ?? 0}",
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[500],
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Build image from Base64 string
  Widget _buildImageFromBase64(String base64String) {
    try {
      if (base64String == null || base64String.isEmpty) {
        return _buildPlaceholderImage();
      }

      // Check if it's a URL instead of Base64
      if (base64String.startsWith('http')) {
        // Return placeholder if it's a URL and not Base64
        print('Image is a URL, not Base64: $base64String');
        return _buildPlaceholderImage();
      }

      // Check and remove Base64 prefix
      if (base64String.startsWith('data:image')) {
        final splitData = base64String.split(',');
        if (splitData.length == 2) {
          base64String = splitData[1];
        }
      }

      // Ensure string is valid Base64
      try {
        // Add padding if needed
        int padLength = 4 - (base64String.length % 4);
        if (padLength < 4) {
          base64String = base64String + ('=' * padLength);
        }

        // Try to decode the Base64 data
        Uint8List imageBytes = base64Decode(base64String);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error displaying Base64 image: $error');
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        print('Error decoding Base64 string: $e');
        return _buildPlaceholderImage();
      }
    } catch (e) {
      print('Error handling image: $e');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[800],
      child: Icon(
        Icons.image,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  // Format timestamp to readable date and time
  String _formatDateTime(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      // If less than 24 hours ago, show relative time
      if (difference.inHours < 24) {
        if (difference.inMinutes < 60) {
          return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
        } else {
          return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
        }
      }
      // If it's today but more than an hour ago
      else if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
        return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      // If it's yesterday
      else if (now.difference(dateTime).inDays == 1) {
        return 'Yesterday, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      // Otherwise show the date
      else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp; // fallback to original format
    }
  }

  // Convert coordinates to a readable location name
  String _formatLocation(double latitude, double longitude) {
    // This is a simplified approach - in a real app you might use reverse geocoding
    // For now, just format the coordinates in a nicer way and add a nearby landmark or city name

    // Round to 2 decimal places for display
    final lat = latitude.toStringAsFixed(2);
    final lon = longitude.toStringAsFixed(2);

    // Hardcoded location names based on coordinates (just as an example)
    // In a real app, you would use reverse geocoding or a location database
    if (latitude > 53.3 && latitude < 53.4 && longitude > -6.3 && longitude < -6.2) {
      return 'Dublin City';
    } else if (latitude > 53.2 && latitude < 53.3 && longitude > -6.2 && longitude < -6.1) {
      return 'South Dublin';
    } else if (latitude > 53.4 && latitude < 53.5 && longitude > -6.2 && longitude < -6.1) {
      return 'North Dublin';
    }

    // Default fallback - still shows coordinates but in a nicer format
    return 'Location: $lat°N, $lon°W';
  }
}
