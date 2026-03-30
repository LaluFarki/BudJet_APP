import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../transaction/controllers/transaction_controller.dart';
import 'widgets/budget_donut_chart.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Kategori (Sedikit lebih cerah/hidup)
    const colorMakanan = Color(0xFFFF7B33); // Orange Vivid Soft
    const colorTransport = Color(0xFF1D9CCB); // Biru Vivid Soft
    const colorTabungan = Color(0xFFBCE037); // Hijau Lime Vivid Soft
    const colorLainnya = Color.fromARGB(255, 225, 225, 225); // Abu-abu jika ada kategori selain 3 di atas

    // Akses controller untuk mengambil data yang reaktif
    final txCtrl = Get.find<TransactionController>();

    final currencyCcy = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Budget Saya',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.textDark, size: 20),
            ),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      // Gunakan Obx agar UI me-render ulang ketika data transaksi / firebase berubah
      body: Obx(() {
        final now = DateTime.now();

        // 1. Hitung total Bulanan & Harian berdasarkan kategori
        double totalBulanan = 0;
        double makanBulanan = 0;
        double transportBulanan = 0;
        double tabunganBulanan = 0;

        double makanHarian = 0;
        double transportHarian = 0;
        double tabunganHarian = 0;

        for (var tx in txCtrl.transactions) {
          if (tx.type == 'expense' &&
              tx.date.month == now.month &&
              tx.date.year == now.year) {
            
            totalBulanan += tx.amount;
            final cat = tx.kategori.toLowerCase();

            // Mapping berdasarkan kata kunci kategori
            if (cat.contains('makan')) {
              makanBulanan += tx.amount;
              if (tx.date.day == now.day) makanHarian += tx.amount;
            } else if (cat.contains('transport')) {
              transportBulanan += tx.amount;
              if (tx.date.day == now.day) transportHarian += tx.amount;
            } else if (cat.contains('tabung')) {
              tabunganBulanan += tx.amount;
              if (tx.date.day == now.day) tabunganHarian += tx.amount;
            }
          }
        }

        double lainnyaBulanan =
            totalBulanan - (makanBulanan + transportBulanan + tabunganBulanan);

        // 2. Kalkulasi Persentase untuk Donut Chart
        double pctMakan = totalBulanan > 0 ? makanBulanan / totalBulanan : 0;
        double pctTransport =
            totalBulanan > 0 ? transportBulanan / totalBulanan : 0;
        double pctTabungan =
            totalBulanan > 0 ? tabunganBulanan / totalBulanan : 0;
        double pctLainnya = totalBulanan > 0 ? lainnyaBulanan / totalBulanan : 0;

        // Bikin segment responsif, sembunyikan jika angkanya 0 dan tampilkan yang ada saja
        final List<DonutSegment> dynamicSegments = totalBulanan > 0
            ? [
                if (pctMakan > 0)
                  DonutSegment(percentage: pctMakan, color: colorMakanan),
                if (pctTransport > 0)
                  DonutSegment(percentage: pctTransport, color: colorTransport),
                if (pctTabungan > 0)
                  DonutSegment(percentage: pctTabungan, color: colorTabungan),
                // Jika total persentase di luar 3 item utama, masukkan abu-abu
                if (pctLainnya > 0)
                  DonutSegment(percentage: pctLainnya, color: colorLainnya),
              ]
            : [
                // Segment kosongan melingkar penuh kalau saldo 0/belum ada pengeluaran
                const DonutSegment(percentage: 1.0, color: Color(0xFFF0F0F0))
              ];

        // Format Teks Utama (cth: Rp 1,5jt)
        String formatSingkatText(double val) {
          if (val == 0) return 'Rp 0';
          if (val >= 1000000) {
            return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}jt';
          }
          if (val >= 1000) {
            return 'Rp ${(val / 1000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}k';
          }
          return currencyCcy.format(val);
        }

        return NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overscroll) {
            overscroll.disallowIndicator(); // Mematikan efek melar (jelly) secara native
            return true;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            children: [
              // 1. KARTU GRAFIK DONUT
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Tombol Edit di pojok kanan atas
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textDark),
                      ),
                    ),

                    // Donut Chart Dinamis
                    BudgetDonutChart(
                      size: 160,
                      totalText: formatSingkatText(totalBulanan),
                      segments: dynamicSegments,
                    ),

                    const SizedBox(height: 32),

                    // Keterangan / Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegend(
                            color: colorMakanan,
                            title: 'MAKAN & MINUM',
                            value: '${(pctMakan * 100).toStringAsFixed(0)}%'),
                        _buildLegend(
                            color: colorTransport,
                            title: 'TRANSPORTASI',
                            value: '${(pctTransport * 100).toStringAsFixed(0)}%'),
                        _buildLegend(
                            color: colorTabungan,
                            title: 'TABUNGAN',
                            value: '${(pctTabungan * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. KARTU RINCIAN BULANAN
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rincian Budget Bulanan',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('3 Item',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      icon: Icons.fastfood_outlined,
                      iconBgColor: const Color(0xFFFFEAE0),
                      iconColor: colorMakanan,
                      title: 'Makan & Minum',
                      amount: currencyCcy.format(makanBulanan),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      icon: Icons.directions_bus_outlined,
                      iconBgColor: const Color(0xFFDCF3FB),
                      iconColor: colorTransport,
                      title: 'Transportasi',
                      amount: currencyCcy.format(transportBulanan),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      icon: Icons.payments_outlined,
                      iconBgColor: const Color(0xFFE9F8C6),
                      iconColor: const Color(0xFF5AB975),
                      title: 'Tabungan',
                      amount: currencyCcy.format(tabunganBulanan),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. KARTU RINCIAN HARIAN
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rincian Budget Harian',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('3 Item',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      icon: Icons.fastfood_outlined,
                      iconBgColor: const Color(0xFFFFEAE0),
                      iconColor: colorMakanan,
                      title: 'Makan & Minum',
                      amount: currencyCcy.format(makanHarian),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      icon: Icons.directions_bus_outlined,
                      iconBgColor: const Color(0xFFDCF3FB),
                      iconColor: colorTransport,
                      title: 'Transportasi',
                      amount: currencyCcy.format(transportHarian),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      icon: Icons.payments_outlined,
                      iconBgColor: const Color(0xFFE9F8C6),
                      iconColor: const Color(0xFF5AB975),
                      title: 'Tabungan',
                      amount: currencyCcy.format(tabunganHarian),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      }),
    );
  }

  Widget _buildLegend(
      {required Color color, required String title, required String value}) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        // Padding nominal ke kanan
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
