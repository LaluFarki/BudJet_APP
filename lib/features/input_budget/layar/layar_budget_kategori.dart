import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LayarBudgetKategori extends StatefulWidget {
  final int totalBudget;
  final List<String> kategoriList;

  const LayarBudgetKategori({
    super.key,
    required this.totalBudget,
    required this.kategoriList,
  });

  @override
  State<LayarBudgetKategori> createState() => _LayarBudgetKategoriState();
}

class _LayarBudgetKategoriState extends State<LayarBudgetKategori> {
  late List<TextEditingController> controllers;

  final NumberFormat currencyFormat =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();

    List<String> defaultKategori = [
      "Makanan & Minuman",
      "Transportasi",
      "Hiburan",
      "Tabungan"
    ];

    for (var kategori in defaultKategori) {
      if (!widget.kategoriList.contains(kategori)) {
        widget.kategoriList.add(kategori);
      }
    }

    controllers = List.generate(
      widget.kategoriList.length,
          (index) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void formatRupiah(TextEditingController controller, String value) {
    String angka = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (angka.isEmpty) {
      controller.clear();
      return;
    }

    int number = int.parse(angka);
    String formatted = currencyFormat.format(number);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  IconData getIcon(String kategori) {
    kategori = kategori.toLowerCase();

    if (kategori.contains("makan") || kategori.contains("minum")) {
      return Icons.fastfood;
    } else if (kategori.contains("transport")) {
      return Icons.directions_bus;
    } else if (kategori.contains("hibur")) {
      return Icons.movie;
    } else if (kategori.contains("tabung")) {
      return Icons.savings;
    } else {
      return Icons.category;
    }
  }

  Color getColor(String kategori) {
    kategori = kategori.toLowerCase();

    if (kategori.contains("makan") || kategori.contains("minum")) {
      return Colors.orange.shade200;
    } else if (kategori.contains("transport")) {
      return Colors.blue.shade200;
    } else if (kategori.contains("hibur")) {
      return Colors.purple.shade200;
    } else if (kategori.contains("tabung")) {
      return Colors.green.shade200;
    } else {
      return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    const int totalStep = 3;
    double progress = 2 / totalStep;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              ),

              const SizedBox(height: 50),

              const Center(
                child: Text(
                  "Budget Kategori",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// LIST KATEGORI
              Expanded(
                child: ListView.builder(
                  itemCount: widget.kategoriList.length,
                  itemBuilder: (context, index) {
                    String kategori = widget.kategoriList[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: getColor(kategori),
                            child: Icon(
                              getIcon(kategori),
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kategori,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: controllers[index],
                                  keyboardType:
                                  TextInputType.number,
                                  onChanged: (value) =>
                                      formatRupiah(
                                          controllers[index], value),
                                  decoration: InputDecoration(
                                    hintText: "Rp 0",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                      borderSide:
                                      BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// bagan bawah cocok dan simpan
              Center(
                child: Text(
                  "Sudah cocok?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFD6E85A),
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    for (int i = 0;
                    i < controllers.length;
                    i++) {
                      print(
                          "${widget.kategoriList[i]} : ${controllers[i].text}");
                    }
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}