import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController {
  // Reactive states
  var name = 'Rian Setyo'.obs;
  var email = 'rian@gmail.com'.obs;
  var password = '***********'.obs;
  var profileImagePath = ''.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
  }

  // Load state from local SharedPreferences
  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      name.value = prefs.getString('profile_name') ?? 'Rian Setyo';
      email.value = prefs.getString('profile_email') ?? 'rian@gmail.com';
      password.value = prefs.getString('profile_password') ?? '***********';
      profileImagePath.value = prefs.getString('profile_image_path') ?? '';
    } catch (e) {
      print("Error loading shared preferences: $e");
    }
  }

  // Update Name
  Future<void> updateName(String newName) async {
    name.value = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', newName);
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    email.value = newEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_email', newEmail);
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    password.value = newPassword;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_password', newPassword);
  }

  // Pick Image from Local Gallery
  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Cek dan set path baru
        profileImagePath.value = image.path;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', image.path);
        
        Get.snackbar(
          'Tersimpan',
          'Foto profil Anda berhasil diganti!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Tidak dapat memilih gambar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
