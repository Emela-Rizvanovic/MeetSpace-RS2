import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class QrTicketValidationDialog extends StatefulWidget {
  const QrTicketValidationDialog({super.key});

  @override
  State<QrTicketValidationDialog> createState() =>
      _QrTicketValidationDialogState();
}

class _QrTicketValidationDialogState
    extends State<QrTicketValidationDialog> {
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const Color cardColor = Color(0xFF2E2E2E);
  static const Color brandOrange = Color(0xFFA56E09);

  Future<void> _scanQrImage() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (picked == null || picked.files.single.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final decoded = await zx.readBarcodeImagePathString(
  picked.files.single.path!,
  DecodeParams(
    imageFormat: ImageFormat.rgb,
    format: Format.qrCode,
    tryHarder: true,
    tryRotate: true,
    tryInverted: true,
    tryDownscale: true,
    maxSize: 1600,
  ),
);

      if (!decoded.isValid || decoded.text == null || decoded.text!.isEmpty) {
        setState(() {
          _error = "QR code could not be read from the selected image.";
          _isLoading = false;
        });
        return;
      }

      final validation = await context
          .read<AuthProvider>()
          .bookingService
          .validateTicket(decoded.text!);

      setState(() {
        _result = validation;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = "Ticket validation failed.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _result?["isValid"] == true;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Validate QR ticket",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 30,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              "Select a QR image shown by the user to validate the reservation ticket.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _scanQrImage,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  _isLoading ? "Scanning..." : "Choose QR image",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 28),
              const Center(
                child: CircularProgressIndicator(
                  color: brandOrange,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 24),
              _statusBox(
                color: Colors.red,
                icon: Icons.error_outline,
                title: "Invalid QR",
                message: _error!,
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              _statusBox(
                color: isValid ? Colors.green : Colors.red,
                icon: isValid
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                title: isValid ? "Valid ticket" : "Invalid ticket",
                message: _result?["message"] ?? "",
              ),
              const SizedBox(height: 18),
              _details(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBox({
    required Color color,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _detailRow("Booking", "#${_result?["bookingId"] ?? "-"}"),
          _detailRow("User", _result?["userFullName"] ?? "-"),
          _detailRow("Username", _result?["username"] ?? "-"),
          _detailRow("Space", _result?["spaceName"] ?? "-"),
          _detailRow("Address", _result?["facilityAddress"] ?? "-"),
          _detailRow("Booking status", _result?["bookingStatus"] ?? "-"),
          _detailRow("Payment status", _result?["paymentStatus"] ?? "-"),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}