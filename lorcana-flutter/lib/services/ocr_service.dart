import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/card_model.dart';

class OcrResult {
  final LorcanaCard? exactMatch;
  final List<LorcanaCard> candidates;

  const OcrResult({this.exactMatch, this.candidates = const []});

  bool get hasMatch => exactMatch != null || candidates.isNotEmpty;
}

/// Herkent Lorcana-kaarten via ML Kit (iOS + Android).
/// Werkt op dezelfde manier als OCRScanService.swift in de iOS app.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<OcrResult> scanCard({
    required File imageFile,
    required List<LorcanaCard> allCards,
    int? selectedSetNumber,
  }) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text.toUpperCase();

    // Zoek kaartnummer patroon: bijv. "42/204" of "042/204"
    final numberPattern = RegExp(r'(\d{1,3})\s*/\s*(\d{2,3})');
    final match = numberPattern.firstMatch(text);

    if (match != null) {
      final cardNum = int.tryParse(match.group(1) ?? '') ?? 0;

      // Filter op geselecteerde set als die er is
      final pool = selectedSetNumber != null
          ? allCards.where((c) => c.setNumber == selectedSetNumber).toList()
          : allCards;

      // Exacte match op kaartnummer
      final exact = pool.where((c) => c.cardNumber == cardNum).toList();
      if (exact.length == 1) return OcrResult(exactMatch: exact.first);
      if (exact.isNotEmpty) return OcrResult(candidates: exact.take(5).toList());
    }

    // Fuzzy: zoek kaartnaaam in de tekst
    final candidates = allCards
        .where((c) => text.contains(c.name.toUpperCase()))
        .take(5)
        .toList();

    if (candidates.length == 1) return OcrResult(exactMatch: candidates.first);
    return OcrResult(candidates: candidates);
  }

  void dispose() => _recognizer.close();
}
