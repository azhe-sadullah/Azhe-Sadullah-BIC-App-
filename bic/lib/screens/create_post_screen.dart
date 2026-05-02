import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import '../services/image_picker_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/fix_user_profile.dart';
import '../models/user_model.dart';
import '../view_model/language/language_provider.dart';
import 'location_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _businessLocationCtrl = TextEditingController();
  final _imagePickerService = ImagePickerService();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  dynamic _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final List<String> _taggedUsers = [];

  @override
  void dispose() {
    _captionController.dispose();
    _businessLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePickerService.pickImageFromGallery();
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _createPost() async {
    if (_selectedImage == null) { _showError('تکایە وێنەیەک هەڵبژێرە'); return; }
    if (_captionController.text.trim().isEmpty) { _showError('تکایە کورتەیەک بنووسە'); return; }

    setState(() { _isUploading = true; _uploadProgress = 0.0; });

    try {
      var user = await _authService.getCurrentUserData();
      if (user == null) {
        final fixed = await fixUserProfile();
        if (fixed) user = await _authService.getCurrentUserData();
        if (user == null) { _showError('تکایە دووبارە login بکەرەوە'); return; }
      }

      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrl = await _storageService.uploadPostImage(
        userId: user.id, postId: postId, imageFile: _selectedImage,
        onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
      );

      final locationText = _businessLocationCtrl.text.trim();
      await _firestoreService.createPost({
        'id': postId, 'userId': user.id, 'username': user.username,
        'userAvatar': user.avatar ?? '', 'imageUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'likesCount': 0, 'commentsCount': 0, 'likes': [], 'images': [imageUrl],
        'createdAt': DateTime.now(), 'updatedAt': DateTime.now(),
        if (locationText.isNotEmpty) 'locationName': locationText,
        if (_taggedUsers.isNotEmpty) 'taggedUsers': _taggedUsers,
      });
      await _firestoreService.updateUser(user.id, {'postsCount': user.postsCount + 1});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پۆست بەسەرکەوتوویی دروستکرا ✓'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('createPost error: $e\n$st');
      _showError('کێشەیەک ڕووی دا: $e');
    } finally {
      if (mounted) setState(() { _isUploading = false; _uploadProgress = 0.0; });
    }
  }

  Future<void> _pickBusinessLocation() async {
    final result = await Navigator.push<LocationResult>(
      context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null) setState(() => _businessLocationCtrl.text = result.locationName);
  }

  Future<void> _showTagPeople() async {
    final searchController = TextEditingController();
    List<UserModel> searchResults = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              const Text('تاگکردنی کەسان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'گەڕان بۆ بەکارهێنەر...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) async {
                  if (val.trim().isEmpty) { setModal(() => searchResults = []); return; }
                  try {
                    final r = await _firestoreService.searchUsers(val.trim());
                    setModal(() => searchResults = r);
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 8),
              ...searchResults.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatar?.isNotEmpty == true ? NetworkImage(user.avatar!) : null,
                  child: user.avatar?.isEmpty ?? true ? Text(user.username[0].toUpperCase()) : null,
                ),
                title: Text(user.username),
                trailing: _taggedUsers.contains(user.username) ? const Icon(Icons.check_circle, color: Color(0xFF3897F0)) : null,
                onTap: () {
                  setState(() { if (!_taggedUsers.contains(user.username)) _taggedUsers.add(user.username); });
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final isKurdish = context.watch<LanguageProvider>().isKurdish;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        title: Text(isKurdish ? 'پۆستی نوێ' : 'New Post', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (!_isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _createPost,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3897F0), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: Text(isKurdish ? 'بڵاوکەرەوە' : 'Share', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      body: _isUploading ? _buildUploadingView() : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 16),
            _buildCaptionSection(isKurdish),
            const SizedBox(height: 12),
            _buildOptionsSection(isKurdish),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 340,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: _selectedImage == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF3897F0).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Ionicons.image_outline, size: 48, color: Color(0xFF3897F0)),
                ),
                const SizedBox(height: 16),
                Text('وێنە هەڵبژێرە', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('دەست بکە بە پۆست کردن', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])
            : Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: kIsWeb
                      ? Image.memory(_selectedImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Image.file(_selectedImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }

  Widget _buildCaptionSection(bool isKurdish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isKurdish ? 'کورتەیەک بنووسە' : 'Write a caption', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _captionController,
            maxLines: 3, maxLength: 200,
            textDirection: isKurdish ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: isKurdish ? 'چی دەتەوێت بگەیەنیت؟' : 'What would you like to share?',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3897F0), width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(bool isKurdish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _optionItem(
          icon: _businessLocationCtrl.text.isNotEmpty ? Ionicons.location : Ionicons.location_outline,
          iconColor: _businessLocationCtrl.text.isNotEmpty ? Colors.red : null,
          title: _businessLocationCtrl.text.isNotEmpty ? _businessLocationCtrl.text : (isKurdish ? 'شوێنی بزنسەکەت زیاد بکە' : 'Add business location'),
          onTap: _pickBusinessLocation,
        ),
        const SizedBox(height: 8),
        _optionItem(
          icon: Ionicons.pricetag_outline,
          title: _taggedUsers.isEmpty ? (isKurdish ? 'کەس تاگ بکە' : 'Tag people') : _taggedUsers.map((u) => '@$u').join(', '),
          onTap: _showTagPeople,
        ),
      ]),
    );
  }

  Widget _optionItem({required IconData icon, required String title, required VoidCallback onTap, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: iconColor ?? Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[500]),
        ]),
      ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF3897F0).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const CircularProgressIndicator(color: Color(0xFF3897F0), strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        const Text('بارکردنی پۆست...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF3897F0))),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: LinearProgressIndicator(
            value: _uploadProgress, backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3897F0)),
            minHeight: 6, borderRadius: BorderRadius.circular(3),
          ),
        ),
      ]),
    );
  }
}
