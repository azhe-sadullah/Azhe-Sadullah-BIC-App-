import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../services/image_picker_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../view_model/language/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/fix_user_profile.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  dynamic _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final List<String> _taggedUsers = [];

  @override
  void initState() {
    super.initState();
    _pickImage();
  }

  Future<void> _pickImage() async {
    final image = await _imagePickerService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedImage == null) {
      final lang = context.read<LanguageProvider>().strings;
      _showError(lang.isKurdish ? 'تکایە وێنەیەک هەڵبژێرە' : 'Please select an image');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      var user = await _authService.getCurrentUserData();

      if (user == null) {
        final fixed = await fixUserProfile();
        if (fixed) {
          user = await _authService.getCurrentUserData();
        }
        if (user == null) {
          if (mounted) {
            final lang = context.read<LanguageProvider>().strings;
            _showError(lang.isKurdish ? 'تکایە دووبارە چوونەژوورەوە بکەرەوە' : 'Please log in again');
          }
          return;
        }
      }

      final storyId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await _storageService.uploadStoryImage(
        userId: user.id,
        storyId: storyId,
        imageFile: _selectedImage,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      final storyData = {
        'id': storyId,
        'userId': user.id,
        'username': user.username,
        'userAvatar': user.avatar ?? '',
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'views': [],
        'viewsCount': 0,
        if (_taggedUsers.isNotEmpty) 'taggedUsers': _taggedUsers,
      };

      await _firestoreService.storiesCollection.doc(storyId).set(storyData);

      if (!mounted) return;

      final lang = context.read<LanguageProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isKurdish ? 'ستۆری بە سەرکەوتوویی دروستکرا!' : 'Story created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint('createStory error: $e\n$stackTrace');
      if (mounted) {
        final lang = context.read<LanguageProvider>().strings;
        _showError(lang.isKurdish ? 'هەڵە لە دروستکردنی ستۆری: $e' : 'Failed to create story: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _showTagPeople() async {
    final searchController = TextEditingController();
    List<UserModel> searchResults = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final lang = ctx.read<LanguageProvider>().strings;
          return Padding(
          padding: EdgeInsets.only(
            top: 16, left: 16, right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(lang.isKurdish ? 'تاگکردنی کەسان' : 'Tag people',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: lang.searchHint,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onChanged: (val) async {
                  if (val.trim().isEmpty) {
                    setModal(() => searchResults = []);
                    return;
                  }
                  try {
                    final r = await _firestoreService.searchUsers(val.trim());
                    setModal(() => searchResults = r);
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 8),
              ...searchResults.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                      ? NetworkImage(user.avatar!) : null,
                  backgroundColor: Colors.grey[700],
                  child: user.avatar == null || user.avatar!.isEmpty
                      ? Text(user.username[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white)) : null,
                ),
                title: Text('@${user.username}',
                    style: const TextStyle(color: Colors.white)),
                trailing: _taggedUsers.contains(user.username)
                    ? const Icon(Icons.check_circle, color: Color(0xFF3897F0))
                    : null,
                onTap: () {
                  setState(() {
                    if (_taggedUsers.contains(user.username)) {
                      _taggedUsers.remove(user.username);
                    } else {
                      _taggedUsers.add(user.username);
                    }
                  });
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        );
        },
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          lang.isKurdish ? 'دروستکردنی ستۆری' : 'Create Story',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: _isUploading
          ? _buildUploadingView()
          : Stack(
              children: [
                // Full screen image
                if (_selectedImage != null)
                  Center(
                    child: kIsWeb
                        ? Image.memory(
                            _selectedImage,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.file(
                            _selectedImage,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),

                // Bottom action buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tag people button
                          GestureDetector(
                            onTap: _showTagPeople,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: _taggedUsers.isNotEmpty
                                        ? const Color(0xFF3897F0)
                                        : Colors.white54),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Ionicons.pricetag_outline,
                                    color: _taggedUsers.isNotEmpty
                                        ? const Color(0xFF3897F0)
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _taggedUsers.isEmpty
                                        ? (lang.isKurdish ? 'کەس تاگ بکە' : 'Tag someone')
                                        : _taggedUsers.map((u) => '@$u').join(', '),
                                    style: TextStyle(
                                      color: _taggedUsers.isNotEmpty ? const Color(0xFF3897F0) : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                        children: [
                          // Change photo button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Ionicons.images_outline),
                              label: Text(lang.isKurdish ? 'گۆڕینی وێنە' : 'Change photo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Share story button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _createStory,
                              icon: const Icon(Ionicons.paper_plane),
                              label: Text(lang.publish),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3897F0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUploadingView() {
    final lang = context.read<LanguageProvider>().strings;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              lang.isKurdish ? 'بڵاوکردنەوەی ستۆریەکەت...' : 'Sharing your story...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3897F0)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3897F0)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
