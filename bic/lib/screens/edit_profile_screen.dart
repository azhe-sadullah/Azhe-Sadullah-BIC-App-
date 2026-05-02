import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/image_picker_service.dart';
import '../models/user_model.dart';
import '../view_model/language/language_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _imagePickerService = ImagePickerService();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();

  UserModel? _currentUser;
  dynamic _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _usernameController.text = user.username;
          _fullNameController.text = user.fullName ?? '';
          _bioController.text = user.bio ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final lang = context.read<LanguageProvider>().strings;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Ionicons.camera_outline),
              title: Text(lang.isKurdish ? 'وێنە بگرە' : 'Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _imagePickerService.pickImageFromCamera();
                if (img != null && mounted) setState(() => _selectedImage = img);
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.images_outline),
              title: Text(lang.isKurdish ? 'هەڵبژێرە لە گەلەری' : 'Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _imagePickerService.pickImageFromGallery();
                if (img != null && mounted) setState(() => _selectedImage = img);
              },
            ),
            if (_currentUser?.avatar?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Ionicons.trash_outline, color: Colors.red),
                title: Text(lang.isKurdish ? 'سڕینەوەی وێنە' : 'Remove photo', style: const TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); setState(() => _selectedImage = null); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    final lang = context.read<LanguageProvider>().strings;

    if (_usernameController.text.trim().isEmpty) {
      _showError(lang.isKurdish ? 'ناوی بەکارهێنەر نابێت بەتاڵ بێت' : 'Username cannot be empty');
      return;
    }

    if (_usernameController.text.trim() != _currentUser!.username) {
      final available = await _firestoreService.isUsernameAvailable(_usernameController.text.trim());
      if (!available) {
        if (mounted) _showError(lang.isKurdish ? 'ئەم ناوە پێشتر بەکارهێنراوە' : 'Username already taken');
        return;
      }
    }

    setState(() { _isSaving = true; _uploadProgress = 0.0; });

    try {
      String? avatarUrl = _currentUser!.avatar;
      if (_selectedImage != null) {
        avatarUrl = await _storageService.uploadProfilePicture(
          userId: _currentUser!.id,
          imageFile: _selectedImage,
          onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
        );
      }

      await _firestoreService.updateUser(_currentUser!.id, {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar': avatarUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.isKurdish ? 'پڕۆفایل بە سەرکەوتوویی نوێکرایەوە!' : 'Profile updated successfully!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() { _isSaving = false; _uploadProgress = 0.0; });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().strings;

    if (_isLoading) return Scaffold(appBar: AppBar(title: Text(lang.editProfile)), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.editProfile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveProfile,
              child: Text(lang.done, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
            ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(lang.isKurdish ? 'پاشەکەوت دەکرێت...' : 'Saving...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  if (_uploadProgress > 0 && _uploadProgress < 1) ...[
                    const SizedBox(height: 12),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: LinearProgressIndicator(value: _uploadProgress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                    ),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200], border: Border.all(color: Colors.blue, width: 3)),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? kIsWeb ? Image.memory(_selectedImage, fit: BoxFit.cover) : Image.file(_selectedImage, fit: BoxFit.cover)
                                : _currentUser?.avatar?.isNotEmpty == true
                                    ? Image.network(_currentUser!.avatar!, fit: BoxFit.cover)
                                    : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Ionicons.camera, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text(lang.isKurdish ? 'گۆڕینی ڕێسمی پڕۆفایل' : 'Change profile photo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ),
                  const SizedBox(height: 32),
                  _field(_usernameController, lang.isKurdish ? 'ناوی بەکارهێنەر' : 'Username', lang.isKurdish ? 'ناوی بەکارهێنەرت بنووسە' : 'Enter your username'),
                  const SizedBox(height: 20),
                  _field(_fullNameController, lang.isKurdish ? 'ناوی تەواو' : 'Full name', lang.isKurdish ? 'ناوی تەواوت بنووسە' : 'Enter your full name'),
                  const SizedBox(height: 20),
                  _field(_bioController, lang.bio, lang.isKurdish ? 'باسی خۆت بکە' : 'Tell us about yourself', maxLines: 4, maxLength: 150),
                  const SizedBox(height: 24),
                  Text(
                    lang.isKurdish ? 'گۆڕانکارییەکان لە هەموو ئەپەکەدا دەردەکەون' : 'Changes will appear across the app',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
          ),
        ),
      ],
    );
  }
}
