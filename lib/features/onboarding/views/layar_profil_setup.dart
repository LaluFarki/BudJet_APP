import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../input_budget/layar/layar_form_anggaran.dart';

/// Layar setup profil awal yang muncul setelah "Get Started".
/// User memilih nama dan foto profil (avatar cartoon atau galeri).
/// Data disimpan secara lokal (SharedPreferences) — ringan dan cepat.
/// Nama juga dikirim ke Firestore agar sinkron dengan dashboard.
class LayarProfilSetup extends StatefulWidget {
  const LayarProfilSetup({super.key});

  @override
  State<LayarProfilSetup> createState() => _LayarProfilSetupState();
}

class _LayarProfilSetupState extends State<LayarProfilSetup> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Index avatar yang dipilih (-1 = belum pilih, 0-4 = avatar, 99 = galeri)
  int _selectedAvatarIndex = -1;

  // Path gambar dari galeri (null jika belum pilih)
  String? _galleryImagePath;

  bool _isSaving = false;

  // ── Avatar Kartun ──
  // Menggunakan emoji warna-warni sebagai avatar bawaan yang tidak butuh asset file
  static const List<Map<String, dynamic>> _avatars = [
    {'emoji': '🐱', 'label': 'Cat', 'color': Color(0xFFFCE4EC)},
    {'emoji': '🐻', 'label': 'Bear', 'color': Color(0xFFFFF3E0)},
    {'emoji': '🦊', 'label': 'Fox', 'color': Color(0xFFFFF9C4)},
    {'emoji': '🐰', 'label': 'Bunny', 'color': Color(0xFFF3E5F5)},
    {'emoji': '🐼', 'label': 'Panda', 'color': Color(0xFFE8F5E9)},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        setState(() {
          _galleryImagePath = file.path;
          _selectedAvatarIndex = 99; // galeri
        });
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak dapat membuka galeri: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvatarIndex == -1) {
      Get.snackbar(
        'Pilih Foto Profil',
        'Silakan pilih avatar atau foto dari galeri!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();

      // Tentukan path foto yang disimpan
      final String profilePic;
      if (_selectedAvatarIndex == 99) {
        // Gambar dari galeri — simpan path lokal
        profilePic = _galleryImagePath ?? '';
      } else {
        // Avatar emoji — simpan sebagai kode seperti "avatar:0"
        profilePic = 'avatar:$_selectedAvatarIndex';
      }

      // ── Simpan ke SharedPreferences (lokal) ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name);
      await prefs.setString('profile_image_path', profilePic);

      // ── Kirim nama ke Firestore (sinkronisasi ringan) ──
      var uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        uid = userCredential.user?.uid;
      }

      if (uid != null) {
        // Hapus await agar proses tidak terblokir kalau koneksi internet lambat / Firestore nyangkut
        FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'name': name, 'profilePic': profilePic},
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('Gagal sinkron profile ke Firebase: $e');
        });
      }

      // ── Lanjut ke form budget ──
      if (!mounted) return;
      Get.off(() => const LayarFormAnggaran());
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Heading ──
                const Center(
                  child: Text(
                    'Halo! 👋',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Atur profil kamu dulu yuk!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Preview Foto Profil ──
                Center(
                  child: Stack(
                    children: [
                      _buildProfilePreview(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickFromGallery,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4E858),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Label Pilih Avatar ──
                const Text(
                  'Pilih Avatar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 14),

                // ── Grid 5 Avatar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_avatars.length, (index) {
                    final av = _avatars[index];
                    final isSelected = _selectedAvatarIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedAvatarIndex = index;
                        _galleryImagePath = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: av['color'] as Color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF7AB800),
                                  width: 3,
                                )
                              : Border.all(color: Colors.transparent, width: 3),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4E858).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            av['emoji'] as String,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),

                // ── Atau Pilih dari Galeri ──
                Center(
                  child: TextButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Pilih dari Galeri'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Input Nama ──
                const Text(
                  'Nama Kamu',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kamu...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      if (val.trim().length < 2) {
                        return 'Nama terlalu pendek';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // ── Tombol Simpan ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4E858),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Lanjut →',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper: Tampilkan preview foto profil ──
  Widget _buildProfilePreview() {
    if (_selectedAvatarIndex == 99 && _galleryImagePath != null) {
      // Foto dari galeri
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD4E858), width: 3),
          image: DecorationImage(
            image: FileImage(File(_galleryImagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (_selectedAvatarIndex >= 0 && _selectedAvatarIndex < _avatars.length) {
      // Avatar emoji
      final av = _avatars[_selectedAvatarIndex];
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: av['color'] as Color,
          border: Border.all(color: const Color(0xFFD4E858), width: 3),
        ),
        child: Center(
          child: Text(
            av['emoji'] as String,
            style: const TextStyle(fontSize: 56),
          ),
        ),
      );
    } else {
      // Placeholder belum pilih
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }
  }
}
