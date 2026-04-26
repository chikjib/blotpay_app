import 'dart:io';
import 'package:blotpay/screens/AccountPage/account_page.dart';
import 'package:blotpay/widgets/custom_button.dart';
import 'package:blotpay/widgets/custom_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../DashboardPage/dashboard.dart';


import '../../models/User/user_model.dart';
import '../../providers/UserProvider/user_provider.dart';
import '../../styles/colors.dart';
import '../../utils/send_notification.dart';
import '../../widgets/custom_dialog.dart';

import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  final UserModel? user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? profileImageUrl;
  bool isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    profileImageUrl = widget.user!.data!.profilePicture.toString();
    _fullNameController.text = widget.user!.data!.fullName.toString();
    _emailController.text = widget.user!.data!.email.toString();
    _phoneController.text = widget.user!.data!.phoneNo.toString();
    print("profile Image");
    print(profileImageUrl);
  }

  Future<File> fixExifRotation(File file) async {
    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) return file;

    // This automatically fixes orientation based on EXIF
    final fixedImage = img.bakeOrientation(originalImage);

    final fixedBytes = img.encodeJpg(fixedImage);
    final newFile = await file.writeAsBytes(fixedBytes, flush: true);

    return newFile;
  }

  Future<File> stripExifData(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return file;

  // Re-encode without EXIF metadata
  final strippedBytes = img.encodeJpg(image, quality: 95);

  final tempDir = Directory.systemTemp;
  final strippedFile = File('${tempDir.path}/no_exif_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await strippedFile.writeAsBytes(strippedBytes, flush: true);

  return strippedFile;
}


  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      file = await fixExifRotation(file); // 👈 fix orientation here
      file = await stripExifData(file);
      setState(() {
        _imageFile = file;
      });
    }
  }

  /// Load and automatically correct image orientation for both JPEG and PNG.
  Future<ImageProvider> loadFixedNetworkImage(String url) async {
    print("new profile image");
    print(url);
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

  String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_isSubmitting, // ✅ block back if still loading
        onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        debugPrint("Back press blocked while loading...");
      }
    },
    child: Scaffold(
      backgroundColor: myLightGrey,
      appBar: AppBar(
        backgroundColor: myLightGrey,
        elevation: 0,
        title: const Text(
          'Profile Details',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 15),

                // Profile Picture
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: black, // border color
                          width: 3, // border thickness
                        ),
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageFile != null
                                ? Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            )
                                : (profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty &&
                                profileImageUrl != "null"
                                ? FutureBuilder<ImageProvider>(
                              future: loadFixedNetworkImage(profileImageUrl!), // ✅ fix orientation
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting ||
                                    snapshot.hasError ||
                                    !snapshot.hasData) {
                                  // ✅ static placeholder
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
                            )),

                            // ✅ dimming overlay
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  widget.user!.data!.fullName.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: Icon(LucideIcons.badgeCheck600),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        toSentenceCase(widget.user!.data!.userLevel.toString()),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name (Read Only)
                customTextField(
                  title: 'Full Name',
                  controller: _fullNameController,
                  type: TextInputType.text,
                  myIcon: const Icon(Icons.person_outlined, size: 30),
                ),

                const SizedBox(height: 15),

                // Email (Read Only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: black,
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.transparent,
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 25.0,
                            horizontal: 16.0,
                          ),

                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                          suffixIcon: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Phone Number (Editable)
                customTextField(
                  title: 'Phone Number',
                  controller: _phoneController,
                  type: TextInputType.text,
                  myIcon: const Icon(Icons.phone_android, size: 30),
                ),

                const SizedBox(height: 30),

                // Save Button
                Consumer<UserProvider>(
                  builder: (context, userUpdate, child) {
                    return customButton(
                      text: 'Save Changes',
                      fontSize: 18,
                      tap: () async {
                        if (_isSubmitting) return;

                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          setState(() => _isSubmitting = true);

                          final result = await userUpdate.updateUser(
                            photo: _imageFile, // File? type
                            fullName: _fullNameController.text.trim(),
                            phoneNo: _phoneController.text.trim(),
                            context: context,
                          );

                          if (!mounted) return;
                          setState(() => _isSubmitting = false);

                          // ✅ Handle result directly
                          if (result["success"] == true) {
                            sendNotification("User Update", "Your profile has been updated");
                            customDialogSuccess(
                              context,
                              result["message"],
                              "User Update",
                              const Dashboard(),
                            );
                          } else {
                            customDialogError(
                              context,
                              result["message"],
                              "User Update",
                            );
                          }
                        }
                      },
                      context: context,
                      status: userUpdate.status,
                    );
                  },
                )

              ],
            ),
          ),
        ),
      ),
    )
    );
  }
}
