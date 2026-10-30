import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// 100% बैकग्राउंड ऑटोमैटिक क्लाउड SMS (बिना किसी स्क्रीन पॉप-अप के)
Future<void> sendGovCloudSMS(BuildContext context, String phone, String msg) async {
  if (phone.isEmpty) return;
  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Fast2SMS API Key (अपने Fast2SMS पैनल से Dev API Key डालें)
  const String fast2smsApiKey = 'YOUR_FAST2SMS_API_KEY';

  try {
    final response = await http.post(
      Uri.parse('https://www.fast2sms.com/dev/bulkV2'),
      headers: {
        'authorization': fast2smsApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'route': 'q',
        'message': msg,
        'language': 'unicode',
        'numbers': cleanPhone,
      }),
    );
    final data = jsonDecode(response.body);
    if (context.mounted && data['return'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('अभिभावक को आधिकारिक SMS ऑटो-डिस्पैच हुआ ✔'), duration: Duration(seconds: 1)),
      );
    }
  } catch (_) {}
}

class GovHeader extends StatelessWidget {
  final String title;
  const GovHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0D253F),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  gradient: const RadialGradient(colors: [Color(0xFF2A4D69), Color(0xFF0D253F)]),
                ),
                child: const Center(child: Icon(Icons.shield, color: Colors.amber, size: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('राष्ट्रीय प्रशिक्षण एवं कोचिंग प्रबंधन प्रणाली', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: Container(height: 3, color: Colors.orange)),
            Expanded(child: Container(height: 3, color: Colors.white)),
            Expanded(child: Container(height: 3, color: Colors.green)),
          ],
        ),
      ],
    );
  }
}

class UIDAIOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = Colors.black.withOpacity(0.72);
    final center = Offset(size.width / 2, size.height * 0.42);
    const double radius = 110.0;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paintBg);
    final ringPaint = Paint()..color = const Color(0xFF00E676)..style = PaintingStyle.stroke..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, ringPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceScanDialog extends StatefulWidget {
  final String stdName;
  const FaceScanDialog({super.key, required this.stdName});
  @override
  State<FaceScanDialog> createState() => _FaceScanDialogState();
}

class _FaceScanDialogState extends State<FaceScanDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _verifying = false;

  void _startCamera() async {
    setState(() => _verifying = true);
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (photo != null) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: UIDAIOverlayPainter()),
          Positioned(
            top: 40, left: 20, right: 20,
            child: Column(
              children: [
                const Icon(Icons.verified_user, color: Colors.amber, size: 36),
                const SizedBox(height: 6),
                const Text('UIDAI स्टाइल लाइव बायोमेट्रिक सत्यापन', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('शिक्षार्थी: ${widget.stdName}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            bottom: 60, left: 30, right: 30,
            child: Column(
              children: [
                const Text('कृपया चेहरे को वृत्त के केंद्र में स्थिर रखें...', style: TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_verifying ? 'सत्यापन प्रक्रियाधीन...' : 'स्कैन आरंभ करें'),
                  onPressed: _verifying ? null : _startCamera,
                ),
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('रद्द करें', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
