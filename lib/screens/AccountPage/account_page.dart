import 'dart:convert';

import 'package:blotpay/helpers/auth_helpers.dart';
import 'package:blotpay/screens/AccountPage/biometric_page.dart';
import 'package:blotpay/screens/AccountPage/change_pin_page.dart';
import 'package:blotpay/screens/AccountPage/create_pin_page.dart';
import 'package:blotpay/screens/AccountPage/profile_details.dart';
import 'package:blotpay/screens/AccountPage/request_account_page.dart';
import 'package:blotpay/screens/AccountPage/reset_pin_page.dart';
import 'package:blotpay/screens/AccountPage/support_page.dart';
import 'package:blotpay/screens/AccountPage/referral_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blotpay/models/User/user_model.dart';
import 'package:blotpay/providers/Database/db_provider.dart';
import 'package:blotpay/screens/AccountPage/change_password_page.dart';
import 'package:blotpay/screens/AccountPage/account_levels_page.dart';
import 'package:blotpay/styles/colors.dart';
import 'package:blotpay/utils/routers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/shimmer_loader.dart';
import '../Authentication/login.dart';

import 'dart:typed_data';
import 'package:image/image.dart' as img;


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future userDetails = DatabaseProvider().getUserDetails();
  UserModel? user;
  String? fullName;
  String? userName;
  String? userLevel;
  String? email;
  String? phone;
  String? profileImageUrl;
  bool _loading = true;     // 👈 for shimmer/loader state
  bool _refreshing = false; // 👈 to prevent duplicate API calls

  bool _isEnabled = false; // default
  bool _loadingPrefs = true; // wait until pref loads



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUser();
    _loadNotificationPref(); // 👈 load OneSignal pref

  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("push_notifications_enabled") ?? false;
    setState(() {
      _isEnabled = enabled;
      _loadingPrefs = false;
    });
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

  Future<void> _updateNotificationStatus(bool enabled) async {
    try {
      final body = {
        "full_name": fullName,
        "enable_push_notification": enabled
      };
      print(body);
      final response = await authPut(
        "/update-user-profile/", body, context: context);

      if (response.statusCode == 200) {
        print("📡 Server updated: Notifications ${enabled ? "enabled" : "disabled"}");
      } else {
        print("❌ Failed to update server: ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error updating notification status: $e");
    }
  }


  Future<void> _toggleNotification(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("push_notifications_enabled", enable);

    try {
      if (enable) {
        // Request permission from OS
        final accepted =
        await OneSignal.Notifications.requestPermission(true);

        if (accepted) {
          await OneSignal.User.pushSubscription.optIn();

          // ✅ Update backend
          await _updateNotificationStatus(true);

          print("✅ Push Notifications Enabled");
        } else {
          setState(() => _isEnabled = false); // revert toggle
          await prefs.setBool("push_notifications_enabled", false);
          print("❌ User denied permission");
        }
      } else {
        await OneSignal.User.pushSubscription.optOut();

        // ✅ Update backend
        await _updateNotificationStatus(false);

        print("🔕 Push Notifications Disabled");
      }
    } catch (e) {
      print("⚠️ Error toggling notifications: $e");
    }
  }


  String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _loadUser() async {
    // 1. Load from cache first
    final cachedUser = await DatabaseProvider().getUserDetails();
    if (mounted) {
      setState(() {
        user = cachedUser;
        profileImageUrl = user?.data?.profilePicture?.toString();
        fullName = user?.data?.fullName ?? "";
        userName = user?.data?.username ?? "";
        email = user?.data?.email ?? "";
        phone = user?.data?.phoneNo ?? "";
        _isEnabled = user?.data?.enablePushNotification ?? false;
        print(_isEnabled);


        final userLevelWord = user?.data?.userLevel ?? "";
        if (userLevelWord.isNotEmpty) {
          userLevel =
              userLevelWord[0].toUpperCase() + userLevelWord.substring(1);
        }

        _loading = false; // stop shimmer after cached data loads
      });
    }

    if(_isEnabled) {
      final accepted =
      await OneSignal.Notifications.requestPermission(true);

      if (accepted) {
        await OneSignal.User.pushSubscription.optIn();

        print("✅ Push Notifications Enabled");
      }
    }

    // 2. Refresh from API
    _refreshUser();
  }

  Future<void> _refreshUser() async {
    if (_refreshing) return; // avoid duplicate requests
    setState(() => _refreshing = true);

    try {
      final freshUser = await UserProvider().getUser(context: context); // 👈 API call

      if (mounted) {
        setState(() {
          user = freshUser;
          profileImageUrl = user?.data?.profilePicture?.toString();
          fullName = user?.data?.fullName ?? "";
          userName = user?.data?.username ?? "";
          email = user?.data?.email ?? "";
          phone = user?.data?.phoneNo ?? "";
          _isEnabled = user?.data?.enablePushNotification ?? false;

          final userLevelWord = user?.data?.userLevel ?? "";
          if (userLevelWord.isNotEmpty) {
            userLevel =
                userLevelWord[0].toUpperCase() + userLevelWord.substring(1);
          }
        });
      }
        } catch (e) {
      debugPrint("Error refreshing user: $e");
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }

    if(_isEnabled) {
      final accepted =
      await OneSignal.Notifications.requestPermission(true);

      if (accepted) {
        await OneSignal.User.pushSubscription.optIn();

        print("✅ Push Notifications Enabled");
      }
    }

  }

  void _showManagePinSheet(BuildContext context) {
    final DraggableScrollableController _controller =
        DraggableScrollableController();
    final sheetContext = context;
    bool _isClosing = false;
    bool _isAnimating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: myLightGrey,
      builder: (context) {
        return DraggableScrollableSheet(
          controller: _controller,
          expand: false,
          initialChildSize: 0.40,
          minChildSize: 0.40,
          maxChildSize: 0.40,
          builder: (context, scrollController) {
            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final size = notification.extent;

                if (size > 0.40 && !_isAnimating) {
                  _isAnimating = true;
                  _controller
                      .animateTo(
                        0.40,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                      .whenComplete(() {
                        _isAnimating = false;
                      });
                }

                if (size < 0.40 && !_isClosing) {
                  _isClosing = true;
                  Navigator.of(sheetContext).pop();
                }

                return true;
              },
              child: SingleChildScrollView(
                controller: scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.topLeft,
                          child: const Text(
                            "Manage Pin",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "What do you want to do?",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 20),

                        user!.data!.transactionPin == null
                            ? buildOptionTile(
                                LucideIcons.shield,
                                "Create Pin",
                                "create transaction pin",
                                () {
                                  PageNavigator(
                                    ctx: context,
                                  ).nextPage(page: const CreatePinPage());
                                },
                              )
                            : buildOptionTile(
                                LucideIcons.shield,
                                "Change Pin",
                                "edit transaction pin",
                                () {
                                  PageNavigator(
                                    ctx: context,
                                  ).nextPage(page: const ChangePinPage());
                                },
                              ),
                        buildOptionTile(
                          LucideIcons.shieldAlert,
                          "Reset Pin",
                          "Forgot your pin? Reset it",
                          () {
                            PageNavigator(
                              ctx: context,
                            ).nextPage(page: ResetPinPage(user: user));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildOptionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      color: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 0,
      shadowColor: white,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: myLightGrey,
          radius: 30,
          child: Icon(icon, color: black, size: 30),
        ),
        title: Text(title, style: TextStyle(color: black, fontSize: 16)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<bool> _showCloseAccountDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm Close Account"),
            content: const Text(
              "Are you sure you want to close your account? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor, // text color
                ),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // button color
                  foregroundColor: Colors.white, // text color
                ),
                child: const Text("Yes, Close"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _loading
                      ? const ShimmerLoader(
                    height: 60,
                    width: 60,
                    radius: 60,
                  ):
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Profile with circular border + dim overlay
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: black,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.3), // ✅ dim effect
                              BlendMode.darken,
                            ),
                            child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty &&
                                profileImageUrl != "null"
                                ? FutureBuilder<ImageProvider>(
                              future: loadFixedNetworkImage(profileImageUrl!), // ✅ fix orientation
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting ||
                                    snapshot.hasError ||
                                    !snapshot.hasData) {
                                  // ✅ Static placeholder instead of CircleAvatar
                                  return Image.asset(
                                    'assets/images/default_image.png',
                                    fit: BoxFit.contain,
                                  );
                                }
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
                          child: const Icon(
                            LucideIcons.badgeCheck,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // _loading
                      //     ? const ShimmerLoader(
                      //   height: 18,
                      //   width: 120, // adjust width for name
                      //   radius: 4,
                      // )
                      //     :
                      Text(
                        fullName ?? "",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // _loading
                      //     ? const ShimmerLoader(
                      //   height: 14,
                      //   width: 90, // adjust width for username
                      //   radius: 4,
                      // )
                      // :
      Text(
        '@${userName ?? ""}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Level card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: lightPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: primaryColor),
                  const SizedBox(width: 8),
                  // _loading
                  //     ? const ShimmerLoader(
                  //   height: 16,
                  //   width: 140, // adjust width so it looks like "Account Level: ..."
                  //   radius: 4,
                  // )
                  //     :
                  Text(
                    'Account Level: ${userLevel ?? ""}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      PageNavigator(
                        ctx: context,
                      ).nextPage(page: AccountLevelsPage(user: user));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: ProfilePage(user: user));
              },
              child: _buildListTile(
                icon: LucideIcons.user,
                title: 'Profile Details',
              ),
            ),
            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: RequestAccountPage(user: user));
              },
              child: _buildListTile(
                icon: LucideIcons.building2,
                title: 'Request Account Number',
              ),
            ),

            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: AccountLevelsPage(user: user));
              },
              child: _buildListTile(
                icon: FontAwesomeIcons.bars,
                title: 'Account Levels',
              ),
            ),
            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: ReferralPage(user: user));
              },
              child: _buildListTile(
                icon: LucideIcons.users,
                title: 'Referrals',
              ),
            ),
            const SizedBox(height: 25),
            // Security Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Security',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _showManagePinSheet(context);
              },
              child: _buildListTile(
                icon: LucideIcons.lockKeyhole,
                title: 'Manage Pin',
              ),
            ),
            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: ChangePasswordPage());
              },
              child: _buildListTile(
                icon: LucideIcons.lockKeyholeOpen,
                title: 'Change Password',
              ),
            ),

            GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: BiometricsScreen());
              },
              child: _buildListTile(
                icon: LucideIcons.scanFace,
                title: 'Biometrics',
              ),
            ),
            const SizedBox(height: 25),

            // Preference Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preferences',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildListTile(
              icon: LucideIcons.bellRing,
              title: 'Push Notifications',
              trailing: Switch(
                value: _isEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: primaryColor, // red when ON
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: primaryColor.withValues(alpha:0.2), // grey when OFF
                onChanged: (val) {
                  setState(() => _isEnabled = val);
                  _toggleNotification(val);
                },
              ),
            ),
            const SizedBox(height: 25),

            // More Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'More',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return GestureDetector(
              onTap: () async {
                final confirmed = await _showCloseAccountDialog(context);
                if (!confirmed) return;

                final result = await userProvider.closeAccount(context: context);

                if (result['success'] == true) {
                  customDialogSuccess(
                    context,
                    result['message'],
                    "Close Account",
                    const LoginPage(), // redirect after closing
                  );
                  await DatabaseProvider().logOut(context);
                } else {
                  customDialogError(
                    context,
                    result['message'],
                    "Close Account",
                  );
                }
              },
              child: _buildListTile(
                icon: LucideIcons.userX,
                title: 'Close Account',
              ),
            );
          },
        ),

        GestureDetector(
              onTap: () {
                PageNavigator(
                  ctx: context,
                ).nextPage(page: const ContactSupportPage());
              },
              child: _buildListTile(
                icon: LucideIcons.messageCircleMore,
                title: 'Contact Support',
              ),
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 30,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Are You Sure You Want To Logout?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // No Button (Green)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // dismiss
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    "No",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Yes Button (Red)
                                ElevatedButton(
                                  onPressed: () {
                                    DatabaseProvider().logOut(
                                      context,
                                    ); // your logout logic
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    "Yes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: _buildListTile(icon: LucideIcons.logIn, title: 'Logout'),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

Widget _buildListTile({required IconData icon, required String title, Widget? trailing}) {
  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(title),
          trailing: trailing ??
              const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          tileColor: Colors.white,
        ),
      ),
    ],
  );
}
