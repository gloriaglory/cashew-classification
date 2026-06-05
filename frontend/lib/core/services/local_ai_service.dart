import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class LocalAiService {
  static Interpreter? _interpreter;
  static Map<String, dynamic>? _recommendations;
  static bool _initialized = false;

  // Alphabetical order — Keras ImageDataGenerator default
  static const _labels = ['anthracnose', 'gumosis', 'healthy', 'leaf_miner', 'red_rust'];

  static Future<void> init() async {
    if (_initialized) return;
    _interpreter = await Interpreter.fromAsset('assets/models/cashew_model.tflite');
    final jsonStr = await rootBundle.loadString('assets/models/pesticide_recommendations.json');
    _recommendations = jsonDecode(jsonStr) as Map<String, dynamic>;
    _initialized = true;
  }

  static Future<Map<String, dynamic>> predict(File imageFile) async {
    await init();

    final bytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(bytes)!;
    final resized = img.copyResize(rawImage, width: 224, height: 224);

    // The TFLite model expects float32 [0–255] — raw pixel values, no normalisation.
    // Build [1][224][224][3] nested list for tflite_flutter's run() API.
    final inputAs4D = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) {
          final p = resized.getPixel(x, y);
          return <double>[
            p.r.toDouble(),
            p.g.toDouble(),
            p.b.toDouble(),
          ];
        }),
      ),
    );

    final output = [List<double>.filled(5, 0.0)];
    _interpreter!.run(inputAs4D, output);

    final probs = output[0];
    int maxIdx = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxIdx]) maxIdx = i;
    }

    final label = _labels[maxIdx];
    final confidence = probs[maxIdx] * 100.0;
    final rec = _recommendations![label] as Map<String, dynamic>;
    final isHealthy = label == 'healthy';
    final pesticides = rec['pesticides'] as List<dynamic>;

    return {
      'success': true,
      'is_healthy': isHealthy,
      'disease_name': rec['disease'] as String,
      'confidence': confidence,
      'description': rec['symptoms'] as String,
      'symptoms': rec['symptoms'] as String,
      'pesticide_name': pesticides.isNotEmpty ? pesticides[0] as String : '',
      'dosage': rec['frequency'] as String,
      'application_method': rec['best_time'] as String,
      'recommendation': pesticides.join(', '),
      'prevention': rec['prevention'] as String,
      'image_url': null,
      'image_path': imageFile.path,
      'all_scores': {
        for (int i = 0; i < _labels.length; i++)
          _labels[i]: '${(probs[i] * 100).toStringAsFixed(1)}%'
      },
    };
  }

  static void dispose() {
    _interpreter?.close();
    _initialized = false;
  }
}
