import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'ocr_service.dart';
import 'parser_service.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Future<void> Function(ThemeMode) onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _scan(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(sourcePath: picked.path);
    if (cropped == null) return;

    setState(() => _busy = true);
    try {
      final ocr = await OcrService().recognizeText(cropped.path);
      final event = parseFlyerText(ocr.rawText, ocr.blocks);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ReviewScreen(event: event)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CalScan'), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(
                initialThemeMode: widget.currentThemeMode,
                onThemeModeChanged: widget.onThemeModeChanged,
              ),
            ),
          ),
        ),
      ]),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _scan(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _scan(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Pick from Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
