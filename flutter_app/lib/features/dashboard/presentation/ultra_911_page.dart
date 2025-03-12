import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Ultra911Page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Title
            Text(
              "911 Emergency Services",
              style: TextStyle(
                color: Colors.yellow[700],
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Emergency Call Button
            _buildExtendedButton(
              context,
              icon: Icons.phone,
              label: 'Call Emergency Services',
              color: Colors.red,
              onTap: () {
                _callEmergencyNumber('+353892379377'); // Call emergency number
              },
            ),
            SizedBox(height: 20),

            // Alert Button
            _buildExtendedButton(
              context,
              icon: Icons.warning,
              label: 'Send Alert to Contacts',
              color: Colors.orange,
              onTap: () {
                // Placeholder for sending alert functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alert sent to your emergency contacts.')),
                );
              },
            ),
            SizedBox(height: 20),

            // Safety Tips Button
            _buildExtendedButton(
              context,
              icon: Icons.info,
              label: 'View Safety Tips',
              color: Colors.blue,
              onTap: () {
                _showEmergencyInfo(context);
              },
            ),
            SizedBox(height: 20),

            // Other Actions Section
            Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Row of Smaller Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.local_hospital,
                  label: 'Medical',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Medical services selected.')),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.local_police,
                  label: 'Police',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Police services selected.')),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.fire_extinguisher,
                  label: 'Fire',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fire services selected.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to Call Emergency Number
  void _callEmergencyNumber(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('Could not launch $phoneNumber');
      throw 'Could not make the call to $phoneNumber';
    }
  }

  // Extended Full-Width Buttons
  Widget _buildExtendedButton(BuildContext context,
      {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 28),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Small Quick Action Buttons
  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[800],
            child: Icon(icon, color: Colors.yellow[700], size: 30),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Emergency Info Modal
  void _showEmergencyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.black,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Safety Tips",
              style: TextStyle(
                color: Colors.yellow[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "- Stay calm and assess the situation.\n"
              "- Call emergency services if needed.\n"
              "- Avoid hazardous areas.\n"
              "- Keep your phone charged and accessible.",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
