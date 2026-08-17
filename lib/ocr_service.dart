import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final List<TextBlock> blocks;
  OcrResult({required this.rawText, required this.blocks});
}

class OcrService {
  Future<OcrResult> recognizeText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return OcrResult(rawText: result.text, blocks: result.blocks);
    } finally {
      recognizer.close();
    }
  }
}
