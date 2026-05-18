import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

/// Centralized dialog widget — Backlog #8 Fix
/// Memperbaiki masalah popup terlalu transparan dengan:
/// - barrierColor solid (0.65 opacity)
/// - elevation tinggi untuk shadow tegas
/// - backgroundColor putih solid tanpa transparansi
class AppDialog {
  AppDialog._();

  // ─── Warna & Style Konstanta ────────────────────────────────────────────────
  static const Color _barrierColor = Color(0xA6000000); // 65% opacity hitam
  static const double _elevation = 20;
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(24));

  // ─── SUCCESS DIALOG ─────────────────────────────────────────────────────────
  /// Tampilkan dialog sukses setelah update/simpan data.
  /// [message]    : Pesan yang ditampilkan
  /// [buttonLabel]: Label tombol (default: 'Oke')
  /// [onClose]    : Callback opsional setelah tombol ditekan
  static void success({
    required String message,
    String buttonLabel = 'Oke',
    VoidCallback? onClose,
  }) {
    Get.dialog(
      _buildBase(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon centang
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  onClose?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: _barrierColor,
      barrierDismissible: false,
    );
  }

  // ─── ERROR / WARNING DIALOG ──────────────────────────────────────────────────
  /// Tampilkan dialog error atau peringatan.
  static void error({
    required String title,
    required String message,
    String buttonLabel = 'Mengerti',
    IconData icon = Icons.warning_amber_rounded,
    Color iconColor = const Color(0xFFEC6A6A),
    Color iconBgColor = const Color(0xFFFFECEC),
  }) {
    Get.dialog(
      _buildBase(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierColor: _barrierColor,
    );
  }

  // ─── CONFIRM DIALOG ──────────────────────────────────────────────────────────
  /// Dialog konfirmasi dengan 2 tombol (Batal + Konfirmasi).
  /// Mengembalikan `true` jika user menekan konfirmasi, `false`/null jika batal.
  static Future<bool?> confirm({
    required String title,
    required String message,
    String cancelLabel = 'Batal',
    String confirmLabel = 'Lanjutkan',
    Color confirmColor = AppColors.primaryGreen,
    Color confirmTextColor = AppColors.textDark,
    IconData? icon,
    Color iconColor = const Color(0xFFF59E0B),
    Color iconBgColor = const Color(0xFFFFF3CD),
  }) {
    return Get.dialog<bool>(
      _buildBase(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: confirmTextColor,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierColor: _barrierColor,
    );
  }

  // ─── LOADING DIALOG ──────────────────────────────────────────────────────────
  /// Dialog loading dengan background solid — fix untuk transparent loading.
  static void loading({String message = 'Menyimpan...'}) {
    Get.dialog(
      _buildBase(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
      barrierColor: _barrierColor,
      barrierDismissible: false,
    );
  }

  // ─── PRIVATE BUILDER ─────────────────────────────────────────────────────────
  static Dialog _buildBase({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 36,
    ),
  }) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: _elevation,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
