import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> newsItems = [];

  final List<String> randomImages = [
    "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400",
    "https://images.unsplash.com/photo-1517976487492-5750f3195933?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400",
    "https://images.unsplash.com/photo-1593642532973-d31b6557fa68?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400",
  ];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response =
          await http.get(Uri.parse('http://170.106.106.90:8001/news'));
      if (response.statusCode == 200) {
        // Decode response as a List since your API returns a JSON array.
        final List<dynamic> newsData = jsonDecode(response.body) as List;
        final List<Map<String, dynamic>> fetchedNews = newsData.map((news) {
          // Check for cover_link existence and non-empty value.
          final String? coverLink = news["cover_link"] as String?;
          final imageUrl = (coverLink != null && coverLink.trim().isNotEmpty)
              ? coverLink
              : randomImages[Random().nextInt(randomImages.length)];
          return {
            "title": news["title1"] ?? "No Title",
            "description": news["title2"] ?? "No Description Available",
            "time": news["date"] ?? "Unknown Date",
            "location": news["location"] ?? "Unknown Location",
            "image": imageUrl,
            "views": news["views"]?.toString() ?? "0",
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
            child: Image.network(
              news["image"],
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
            ),
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
}
