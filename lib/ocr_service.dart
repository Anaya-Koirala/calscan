import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final List<TextBlock> blocks;
  OcrResult({required this.rawText, required this.blocks});
}

class OcrService {
  // ML Kit recognizer setup is expensive; keep one instance across scans
  // instead of recreating it per image.
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> recognizeText(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    return OcrResult(rawText: result.text, blocks: result.blocks);
  }

  void dispose() {
    _recognizer.close();
  }
}
