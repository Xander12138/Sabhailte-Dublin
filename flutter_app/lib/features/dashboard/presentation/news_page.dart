import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> newsItems = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8001/news'));
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
            "time": news[5],
            "location": "Lat: ${locationData['latitude']}, Lon: ${locationData['longitude']}",
            "views": news[7]?.toString() ?? "0",
            "comments": "0",
            "likes": "0",
          };
        }).toList();

        setState(() {
          newsItems = fetchedNews;
        });
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
              "Nationwide",
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
                    child: CircularProgressIndicator(color: Colors.yellow),
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
                    Icon(Icons.thumb_up, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      news["likes"],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
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

  // Build image from Base64 string
  Widget _buildImageFromBase64(String base64String) {
    try {
      // check and remove Base64 prefix
      if (base64String.startsWith('data:image')) {
        final splitData = base64String.split(',');
        if (splitData.length == 2) {
          base64String = splitData[1];
        }
      }

      // decode Base64 data
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey,
            child: Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 50,
            ),
          );
        },
      );
    } catch (e) {
      print("Error decoding Base64 image: $e");
      return Container(
        color: Colors.grey,
        child: Icon(
          Icons.broken_image,
          color: Colors.white,
          size: 50,
        ),
      );
    }
  }
}
