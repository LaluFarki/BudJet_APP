import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'layar_budget_kategori.dart';

class LayarFormAnggaran extends StatefulWidget {
  const LayarFormAnggaran({super.key});

  @override
  State<LayarFormAnggaran> createState() => _LayarFormAnggaranState();
}

class _LayarFormAnggaranState extends State<LayarFormAnggaran> {
  DateTime? selectedDate;
  final TextEditingController _budgetController = TextEditingController();
  final NumberFormat _formatter = NumberFormat("#,###", "id_ID");

  final int totalStep = 3;

  List<String> kategoriList = [
    "Makanan & Minuman",
    "Transportasi",
    "Hiburan",
    "Tabungan",
  ];

  late List<bool> isSelected;

  @override
  void initState() {
    super.initState();

    // default: belum ada yang dipilih
    isSelected = List.generate(kategoriList.length, (index) => false);

    _budgetController.addListener(() {
      String text = _budgetController.text.replaceAll(".", "");

      if (text.isEmpty) return;

      int? value = int.tryParse(text);
      if (value == null) return;

      String newText = _formatter.format(value).replaceAll(",", ".");

      if (newText != _budgetController.text) {
        _budgetController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });
  }

  Future<void> _pilihTanggal() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _tambahKategori() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tambah Kategori"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Masukkan kategori",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                String newKategori = controller.text.trim();

                if (newKategori.isNotEmpty &&
                    !kategoriList.contains(newKategori)) {
                  setState(() {
                    kategoriList.add(newKategori);
                    isSelected.add(true); // otomatis dipilih
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Tambah"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1 / totalStep;

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
                  const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),

              const SizedBox(height: 50),

              /// FORM
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Detail Budget",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        "Budget Anda",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            prefixText: "Rp ",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Tanggal Dana Masuk",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _pilihTanggal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate == null
                                    ? "Pilih tanggal"
                                    : DateFormat("dd MMMM yyyy")
                                    .format(selectedDate!),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Kategori Belanja",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton(
                        onPressed: _tambahKategori,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text("Buat Kategori"),
                      ),

                      const SizedBox(height: 20),

                      /// 🔥 KATEGORI (INI YANG DIUBAH)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(kategoriList.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                isSelected[index] = !isSelected[index];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected[index]
                                    ? const Color(0xFFD4E858)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected[index]
                                      ? const Color(0xFFD4E858)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    kategoriList[index],
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected[index]
                                        ? Icons.check
                                        : Icons.add,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    int totalBudget = int.parse(
                        _budgetController.text.replaceAll(".", ""));

                    List<String> selectedKategori = [];

                    for (int i = 0; i < kategoriList.length; i++) {
                      if (isSelected[i]) {
                        selectedKategori.add(kategoriList[i]);
                      }
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LayarBudgetKategori(
                              totalBudget: totalBudget,
                              kategoriList: selectedKategori,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFD6E85A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Lanjut",
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}