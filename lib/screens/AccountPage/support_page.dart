import 'package:blotpay/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../styles/colors.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  final String whatsappChannel = AppConstant.whatsappChannel;
  final String emailUs = AppConstant.emailUs;
  final String whatsappNumber = AppConstant.whatsappNumber;
  final String facebookPage = AppConstant.facebookPage;
  final String xPage = AppConstant.xPage;
  final String instagramPage = AppConstant.instagramPage;

  // Function to launch URLs or apps
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _openFreshchat() async {
    Freshchat.showConversations();
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: lightPrimaryColor, // light pink
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 16, color: black),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft600, color: black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ListView(
          children: [
            _buildContactTile(
              icon: FontAwesomeIcons.bullhorn,
              title: "Whatsapp Channel",
              subtitle: "Join our Whatsapp Channel",
              onTap: () => _launchUrl(whatsappChannel), // change number
            ),
            _buildContactTile(
              icon: Icons.chat_bubble_outline,
              title: "Live Chat",
              subtitle: "Get instant support via live chat",
              onTap: _openFreshchat,
            ),
            _buildContactTile(
              icon: LucideIcons.messageSquareText,
              title: "Email us",
              subtitle: "Reach us through our email",
              onTap: () => _launchUrl("mailto:$emailUs"), // change email
            ),
            _buildContactTile(
              icon: FontAwesomeIcons.whatsapp,
              title: "WhatsApp",
              subtitle: "Available 24/7... For swift response",
              onTap: () => _launchUrl("https://wa.me/$whatsappNumber"), // change number
            ),
            _buildContactTile(
              icon: FontAwesomeIcons.facebook,
              title: "Facebook",
              subtitle: "Reach us on Facebook",
              onTap: () => _launchUrl(facebookPage),
            ),
            _buildContactTile(
              icon: FontAwesomeIcons.x,
              title: "X",
              subtitle: "Reach us on X",
              onTap: () => _launchUrl(xPage),
            ),
            _buildContactTile(
              icon: FontAwesomeIcons.instagram,
              title: "Instagram",
              subtitle: "Reach us on Instagram",
              onTap: () => _launchUrl(instagramPage),
            ),
          ],
        ),
      ),
    );
  }
}
