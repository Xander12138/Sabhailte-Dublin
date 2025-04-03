import 'package:flutter/material.dart';
import 'news_page.dart';
import 'map_page.dart';
import 'go_live_page.dart';
import 'ultra_911_page.dart';
import 'alerts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages corresponding to bottom navigation items
  final List<Widget> _pages = [
    NewsPage(), // News Tab
    MapPage(), // Map Tab
    GoLivePage(), // Go Live Tab
    Ultra911Page(), // Ultra 911 Tab
    AlertsPage(), // Alerts Tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text(
          _getTitle(), // Dynamically change title based on selected tab
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Go Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Ultra 911',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  // Get the dynamic title based on the selected tab
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'News';
      case 1:
        return 'Map';
      case 2:
        return 'Go Live';
      case 3:
        return 'Ultra 911';
      case 4:
        return 'Alerts';
      default:
        return '';
    }
  }
}
