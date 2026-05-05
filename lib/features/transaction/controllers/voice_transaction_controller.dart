import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
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

  Map<String, dynamic> _extractAmountAndPriceString(String text) {
    final numberWords = {
      'satu': 1, 'dua': 2, 'tiga': 3, 'empat': 4, 'lima': 5,
      'enam': 6, 'tujuh': 7, 'delapan': 8, 'sembilan': 9,
      'sepuluh': 10, 'sebelas': 11, 'seratus': 100, 'seribu': 1000,
      'sejuta': 1000000, 'nol': 0
    };

    // Normalisasi awalan 'rp' agar lebih mudah dibaca (misal: "rp20000" atau "rp. 20000" jadi "rp 20000")
    String normalizedText = text.replaceAll(RegExp(r'\brp\.?\s*', caseSensitive: false), 'rp ');

    // Regex ini menangkap deretan angka ATAU kata-kata nominal secara utuh (termasuk "15 ribu" atau "dua puluh ribu")
    RegExp moneyPattern = RegExp(r'\b(?:\d+(?:[\.,]\d+)*|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|belas|puluh|seratus|ratus|seribu|ribu|sejuta|juta|rp|rupiah|\s)+\b');
    
    Iterable<RegExpMatch> matches = moneyPattern.allMatches(normalizedText);
    
    double maxAmount = 0.0;
    String exactPriceString = "";

    for (var match in matches) {
      String phrase = match.group(0)!.trim();
      if (phrase.isEmpty) continue;

      double currentTotal = 0;
      double currentTemp = 0;
      bool hasValidNumber = false;

      List<String> tokens = phrase.split(RegExp(r'\s+'));
      
      for (String word in tokens) {
        String cleanWord = word.replaceAll(RegExp(r'[\.,]'), '');
        
        if (double.tryParse(cleanWord) != null) {
          currentTemp += double.parse(cleanWord);
          hasValidNumber = true;
        } else if (numberWords.containsKey(word)) {
          currentTemp += numberWords[word]!;
          hasValidNumber = true;
        } else if (word == 'belas') {
          currentTemp += 10;
        } else if (word == 'puluh') {
          currentTemp = (currentTemp == 0 ? 1 : currentTemp) * 10;
        } else if (word == 'ratus') {
          currentTemp = (currentTemp == 0 ? 1 : currentTemp) * 100;
        } else if (word == 'ribu') {
          currentTotal += (currentTemp == 0 ? 1 : currentTemp) * 1000;
          currentTemp = 0;
          hasValidNumber = true; 
        } else if (word == 'juta') {
          currentTotal += (currentTemp == 0 ? 1 : currentTemp) * 1000000;
          currentTemp = 0;
          hasValidNumber = true;
        }
      }
      currentTotal += currentTemp;

      // Ambil nominal yang paling logis (terbesar) sebagai harga utama
      if (hasValidNumber && currentTotal > maxAmount) {
        maxAmount = currentTotal;
        exactPriceString = phrase; // Simpan kalimat persisnya untuk dihapus nanti
      }
    }

    return {
      'amount': maxAmount,
      'stringToRemove': exactPriceString, 
    };
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

  Map<String, dynamic> _extractDateFromText(String text) {
    DateTime detectedDate = DateTime.now();
    String exactDateString = "";
    String lowerText = text.toLowerCase();

    // Map untuk mengubah kata angka dasar menjadi integer
    final numberWords = {
      'satu': 1, 'dua': 2, 'tiga': 3, 'empat': 4, 'lima': 5,
      'enam': 6, 'tujuh': 7, 'delapan': 8, 'sembilan': 9, 'sepuluh': 10
    };

    // 1. Cek frasa waktu yang eksplisit (Urutan sangat penting, dari yang terpanjang ke terpendek)
    if (lowerText.contains(RegExp(r'\b(kemarin lusa|lusa kemarin)\b'))) {
      detectedDate = DateTime.now().subtract(const Duration(days: 2));
      exactDateString = RegExp(r'\b(kemarin lusa|lusa kemarin)\b').firstMatch(lowerText)?.group(0) ?? "";
    } 
    else if (lowerText.contains(RegExp(r'\b(kemarin)\b'))) {
      detectedDate = DateTime.now().subtract(const Duration(days: 1));
      exactDateString = "kemarin";
    } 
    else if (lowerText.contains(RegExp(r'\b(minggu (kemarin|lalu)|satu minggu (yang )?lalu)\b'))) {
      detectedDate = DateTime.now().subtract(const Duration(days: 7));
      exactDateString = RegExp(r'\b(minggu (kemarin|lalu)|satu minggu (yang )?lalu)\b').firstMatch(lowerText)?.group(0) ?? "";
    } 
    else if (lowerText.contains(RegExp(r'\b(bulan (kemarin|lalu)|satu bulan (yang )?lalu)\b'))) {
      DateTime now = DateTime.now();
      // Mengurangi 1 bulan dengan aman
      detectedDate = DateTime(now.year, now.month - 1, now.day);
      exactDateString = RegExp(r'\b(bulan (kemarin|lalu)|satu bulan (yang )?lalu)\b').firstMatch(lowerText)?.group(0) ?? "";
    } 
    else if (lowerText.contains(RegExp(r'\b(hari ini)\b'))) {
      detectedDate = DateTime.now();
      exactDateString = "hari ini";
    }
    // 2. Cek pola "X hari yang lalu" (contoh: "3 hari lalu", "dua hari yang lalu")
    else {
      RegExp daysAgoRegex = RegExp(r'\b(satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|\d+)\s+hari\s+(yang\s+)?lalu\b');
      var match = daysAgoRegex.firstMatch(lowerText);
      
      if (match != null) {
        String numStr = match.group(1)!;
        int days = int.tryParse(numStr) ?? (numberWords[numStr] ?? 0);
        
        detectedDate = DateTime.now().subtract(Duration(days: days));
        exactDateString = match.group(0)!;
      }
    }

    return {
      'date': detectedDate,
      'stringToRemove': exactDateString,
    };
  }

  // Pastikan import ini ada di paling atas file:
  // import 'package:intl/intl.dart';

  void _extractTransactionData(String text) {
    if (text.isEmpty || text == "Mendengarkan...") {
      transcription.value = "";
      return;
    }

    String lowerText = text.toLowerCase();
    String detectedCat = userCategories.isNotEmpty ? userCategories.first : "Lainnya"; 
    
    // 1. Deteksi Kategori
    for (var cat in userCategories) {
      if (lowerText.contains(cat.toLowerCase())) {
        detectedCat = cat;
        break;
      }
    }

    // 2. Ekstraksi Tanggal (BARU)
    final dateData = _extractDateFromText(lowerText);
    DateTime detectedDate = dateData['date'];
    String dateString = dateData['stringToRemove'];

    // 3. Ekstraksi Harga
    final priceData = _extractAmountAndPriceString(lowerText);
    double detectedAmount = priceData['amount'];
    String priceString = priceData['stringToRemove'];

    // 4. Ekstraksi Judul
    String title = lowerText;
    
    // Hapus frasa waktu dari judul ("kemarin", "minggu lalu")
    if (dateString.isNotEmpty) {
      title = title.replaceFirst(dateString, '');
    }

    // Hapus kalimat harga utama dari judul
    if (priceString.isNotEmpty) {
      title = title.replaceFirst(priceString, '');
    }
    
    // Hapus kategori dari judul
    title = title.replaceAll(RegExp(detectedCat, caseSensitive: false), '');

    // Sapu bersih sisa angka dari judul (Digit maupun Kata)
    title = title.replaceAll(RegExp(r'\b\d+(?:[\.,]\d+)*\b'), '');
    title = title.replaceAll(RegExp(r'\b(satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|belas|puluh|seratus|ratus|seribu|ribu|sejuta|juta)\b', caseSensitive: false), '');

    // Hapus kata-kata filler
    title = title.replaceAll(RegExp(r'\b(untuk|sebesar|kategori|harga|rp|rupiah|beli|bayar|pada|termasuk|seharga|total)\b', caseSensitive: false), '');
    
    // Bersihkan sisa spasi
    title = title.trim().replaceAll(RegExp(r'\s+'), ' '); 

    // Kapitalisasi huruf pertama
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    } else {
      title = "Transaksi Tanpa Judul";
    }

    // 5. Buat objek transaksi dengan tanggal yang terdeteksi
    detectedTx.value = TransactionModel(
      id: '', 
      amount: detectedAmount,
      createdAt: DateTime.now(), // Waktu dicatatnya tetap sekarang
      date: detectedDate,        // Waktu transaksinya menggunakan hasil suara
      kategori: detectedCat,
      note: 'Input via Suara',
      title: title,
      type: 'expense', 
    );

    // Format output teks di layar agar memperlihatkan tanggal yang dideteksi
    String formattedDate = DateFormat('dd MMM yyyy').format(detectedDate);
    transcription.value = "$title untuk $detectedCat sebesar Rp${detectedAmount.toInt()} pada $formattedDate";    
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