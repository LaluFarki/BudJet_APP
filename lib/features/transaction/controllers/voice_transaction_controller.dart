import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceTransactionController extends GetxController {
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  var isSpeechEnabled = false.obs;
  
  // State status
  var isListening = false.obs;
  var isProcessing = false.obs;
  var transcription = "".obs;
  
  // Hasil ekstraksi data
  var detectedTx = Rxn<TransactionModel>();

  // Reactive List untuk menampung kategori user
  final RxList<String> userCategories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    reset(); // Pastikan state bersih saat pertama dibuka
    _initSpeech();
    _loadUserCategories();
  }

  @override
  void onClose() {
    _speechToText.stop();
    super.onClose();
  }

  // Mengambil daftar kategori user dari Firestore (sama seperti di AddTransaction)
  void _loadUserCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _setDefaultCategories();
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      final categoriesRaw = data['categories'] as List<dynamic>? ?? [];
      if (categoriesRaw.isNotEmpty) {
        userCategories.value = categoriesRaw
            .map((e) => (e as Map<String, dynamic>)['nama'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    }
    
    // Fallback jika kosong
    if (userCategories.isEmpty) {
      _setDefaultCategories();
    }
  }

  void _setDefaultCategories() {
    userCategories.value = [
      'Makanan & Minuman',
      'Transportasi',
      'Belanja',
      'Hiburan',
      'Lainnya'
    ];
  }

  void _initSpeech() async {
    isSpeechEnabled.value = await _speechToText.initialize(
      onError: (val) {
        print('Error STT: $val');
        isListening.value = false;
        isProcessing.value = false;
      },
      onStatus: (val) {
        print('Status STT: $val');
      },
    );
  }
  
  void startListening() async {
    if (!isSpeechEnabled.value) {
      Get.snackbar("Error", "Izin mikrofon belum diberikan atau tidak didukung.");
      return;
    }

    reset();
    isListening.value = true;
    transcription.value = "Mendengarkan...";
    
    await _speechToText.listen(
      onResult: (result) {
        // Update secara real-time
        transcription.value = result.recognizedWords;
      },
      localeId: 'id_ID',
    );
  }

  Future<void> stopAndProcess() async {
    if (!isListening.value) return; // Mencegah proses berulang
    
    isListening.value = false;
    isProcessing.value = true;
    
    await _speechToText.stop();

    // Tunggu agar ekstraksi kata terakhir terambil sempurna
    await Future.delayed(const Duration(milliseconds: 600));
    _extractTransactionData(transcription.value);
    
    // PENTING: Reset status memproses agar buffering hilang
    isProcessing.value = false;
  }

  void _extractTransactionData(String text) {
    if (text.isEmpty || text == "Mendengarkan...") {
      transcription.value = "";
      return;
    }

    String lowerText = text.toLowerCase();
    
    // Gunakan kategori default dari list user jika ada
    String detectedCat = userCategories.isNotEmpty ? userCategories.first : "Lainnya"; 
    double detectedAmount = 0;

    // 1. Deteksi Kategori milik User
    for (var cat in userCategories) {
      if (lowerText.contains(cat.toLowerCase())) {
        detectedCat = cat;
        break;
      }
    }

    // 2. Deteksi Angka (Harga)
    RegExp regExp = RegExp(r'\b\d+(?:[\.,]\d+)*\b');
    Iterable<RegExpMatch> matches = regExp.allMatches(lowerText);
    
    if (matches.isNotEmpty) {
      String amountStr = matches.last.group(0)!.replaceAll(RegExp(r'[\.,]'), '');
      detectedAmount = double.tryParse(amountStr) ?? 0;
    }

    // 3. Deteksi Judul
    String title = text;
    title = title.replaceAll(RegExp(detectedCat, caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\b\d+(?:[\.,]\d+)*\b'), '');
    title = title.replaceAll(RegExp(r'\b(untuk|sebesar|kategori|harga|rp|rupiah|beli|bayar|pada)\b', caseSensitive: false), '');
    title = title.trim().replaceAll(RegExp(r'\s+'), ' '); 

    if (title.isEmpty) title = "Transaksi Tanpa Judul";

    // 4. Buat objek transaksi (Biarkan id kosong karena ini transaksi baru)
    detectedTx.value = TransactionModel(
      id: '', 
      amount: detectedAmount,
      createdAt: DateTime.now(),
      date: DateTime.now(),
      kategori: detectedCat,
      note: 'Input via Suara',
      title: title,
      type: 'expense', 
    );

    // Format output rapi
    transcription.value = "$title untuk $detectedCat sebesar Rp${detectedAmount.toInt()}";    
  }

  void reset() {
    isListening.value = false;
    isProcessing.value = false;
    transcription.value = "";
    detectedTx.value = null;
  }

  void saveTransaction() {
    if (detectedTx.value != null) {
      // BUKAN LAGI DISIMPAN LANGSUNG!
      // Lempar data ke AddTransactionScreen sebagai draft untuk diperiksa ulang oleh user
      Get.offNamed('/add-tx', arguments: {
        'isVoiceDraft': true,
        'draftTx': detectedTx.value,
      });
    }
  }
}