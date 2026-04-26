import 'package:flutter/material.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../styles/colors.dart';
import '../../../models/User/user_model.dart';
import '../../../widgets/shimmer_loader.dart';

import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TopBar extends StatelessWidget {
  final UserModel? user;

  const TopBar({super.key, this.user});

  String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _openFreshchat() async {
    Freshchat.showConversations();
  }

  /// Load and automatically correct image orientation for both JPEG and PNG.
  Future<ImageProvider> loadFixedNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final image = img.decodeImage(bytes);
        if (image == null) throw Exception("Could not decode image");

        img.Image oriented = image;
        final lowerUrl = url.toLowerCase();

        if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) {
          // ✅ Auto-fix EXIF orientation for JPEGs
          oriented = img.bakeOrientation(image);
        } else if (lowerUrl.endsWith('.png')) {
          // 🧠 Detect if PNG looks upside down
          if (_looksUpsideDown(image)) {
            oriented = img.flipVertical(image);
            debugPrint("🔄 PNG image flipped vertically (auto-detected)");
          }
        }

        // ✅ Re-encode properly
        final fixedBytes = lowerUrl.endsWith('.png')
            ? img.encodePng(oriented)
            : img.encodeJpg(oriented, quality: 95);

        return MemoryImage(Uint8List.fromList(fixedBytes));
      }
    } catch (e) {
      debugPrint("🧩 Image load error: $e");
    }

    // 🖼️ Fallback image if anything fails
    return const AssetImage('assets/images/default_image.png');
  }

  /// Detects if an image looks upside down by comparing brightness of top and bottom halves.
  bool _looksUpsideDown(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    final int sampleRows = (height * 0.15).toInt(); // use 15% top & bottom slices

    double topBrightness = 0;
    double bottomBrightness = 0;

    for (int y = 0; y < sampleRows; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        topBrightness += img.getLuminance(pixel);
      }
    }

    for (int y = height - sampleRows; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        bottomBrightness += img.getLuminance(pixel);
      }
    }

    // Average brightness
    topBrightness /= (width * sampleRows);
    bottomBrightness /= (width * sampleRows);

    // 🧠 If the bottom is *brighter* than the top significantly,
    // assume the image is upside down (like a face at the bottom)
    final isUpsideDown = bottomBrightness - topBrightness > 30;

    return isUpsideDown;
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = user?.data?.profilePicture ?? "";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (user == null)
          const ShimmerLoader(height: 60, width: 60, radius: 30)
        else
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: black, width: 3),
                ),
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.3), // ✅ use withOpacity
                      BlendMode.darken,
                    ),
                    child: profileImage != null &&
                        profileImage!.isNotEmpty &&
                        profileImage != "null"
                        ? FutureBuilder<ImageProvider>(
                      future: loadFixedNetworkImage(profileImage!), // ✅ fix orientation
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting ||
                            snapshot.hasError ||
                            !snapshot.hasData) {
                          // ✅ Show placeholder while loading or on error
                          return Image.asset(
                            'assets/images/default_image.png',
                            fit: BoxFit.contain,
                          );
                        }
                        // ✅ Once loaded, show the fixed image
                        return Image(
                          image: snapshot.data!,
                          fit: BoxFit.contain,
                        );
                      },
                    )
                        : Image.asset(
                      'assets/images/default_image.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Badge
              Positioned(
                bottom: 2,
                right: -2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.badgeCheck, size: 18, color: white),
                ),
              ),
            ],
          ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user == null)
              const ShimmerLoader(height: 18, width: 120) // name placeholder
            else
              Text(
                "Hi, ${toSentenceCase(user?.data?.fullName?.split(" ").last ?? "")}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (user == null)
              const ShimmerLoader(height: 14, width: 80) // level placeholder
            else
              Text(
                "Account Level: ${toSentenceCase(user?.data?.userLevel ?? "-")}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: _openFreshchat, icon: Icon(LucideIcons.messagesSquare, size: 35)) ,
      ],
    );
  }
}
