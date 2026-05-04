import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../payment_preview/payment_preview_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Parse QR data: credstellar://pay?merchant_name=X&merchant_id=Y
  /// OR upi://pay?pa=...&pn=MerchantName
  /// Returns { merchant_name, merchant_id } or null
  Map<String, String>? _parseQr(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (uri.scheme == 'credstellar' && uri.host == 'pay') {
        final name = uri.queryParameters['merchant_name'];
        final id = uri.queryParameters['merchant_id'] ?? '';
        if (name != null && name.isNotEmpty) {
          return {'merchant_name': name, 'merchant_id': id};
        }
      } else if (uri.scheme == 'upi' && uri.host == 'pay') {
        final name = uri.queryParameters['pn']?.replaceAll('+', ' ');
        final id = uri.queryParameters['pa'] ?? '';
        if (name != null && name.isNotEmpty) {
          return {'merchant_name': name, 'merchant_id': id};
        }
      }
    } catch (_) {}
    return null;
  }

  void _onQrScanned(String data) {
    if (!_isScanning) return;
    
    final parsed = _parseQr(data);
    if (parsed != null) {
      setState(() => _isScanning = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentPreviewScreen(
            merchantName: parsed['merchant_name']!,
            merchantId: parsed['merchant_id'] ?? '',
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isScanning = true);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code. Use a CredStellar QR.')),
      );
    }
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      final success = await _scannerController.analyzeImage(xFile.path);
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid QR code found in the image.')),
          );
        }
      }
      // If success == true, the onDetect callback will be triggered automatically by MobileScanner.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Camera background ──
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _onQrScanned(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // ── Viewfinder overlay ──
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _ViewfinderPainter(),
            ),
          ),
        ),

        // ── Scanning line animation ──
        Center(
          child: SizedBox(
            width: 260,
            height: 280,
            child: _ScanLineWidget(),
          ),
        ),

        // ── Bottom instruction + controls ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Instruction pill
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'Scan any UPI or CredStellar QR to pay',
                  style: AppTheme.bodySm.copyWith(color: AppTheme.textPrimary),
                ),
              ),

              // Control buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controlButton(Icons.flashlight_on_outlined, _toggleTorch),
                    const SizedBox(width: 24),
                    _controlButton(Icons.photo_library_outlined, _pickImage),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ── Viewfinder corner brackets ──
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 30.0;

    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);

    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerLen), paint);

    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Animated scanning line ──
class _ScanLineWidget extends StatefulWidget {
  @override
  State<_ScanLineWidget> createState() => _ScanLineWidgetState();
}

class _ScanLineWidgetState extends State<_ScanLineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(_animation.value),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.primaryBlue,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2));

    canvas.drawLine(
        Offset(10, y), Offset(size.width - 10, y), paint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
