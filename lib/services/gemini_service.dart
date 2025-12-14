import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/microtask_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const String _modelName = 'gemini-2.5-flash';

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
    );
  }

  String _buildPrompt(String userPrompt) {
    return '''
Kamu adalah AI Micro-task Generator untuk aplikasi bernama Eira.

Tugas kamu adalah memecah satu aktivitas utama menjadi beberapa micro-task kecil yang mudah dikerjakan oleh pengguna dengan short attention span.

ATURAN WAJIB:
1. Output HARUS berupa JSON valid.
2. DILARANG menambahkan teks apa pun di luar JSON.
3. DILARANG menggunakan markdown, bullet point, atau penjelasan.
4. Gunakan Bahasa Indonesia yang jelas dan netral.
5. Micro-task harus logis, berurutan, dan realistis.
6. Jumlah micro-task antara 3 sampai 7.

FORMAT JSON WAJIB (TIDAK BOLEH BERUBAH):

{
  "isValid": true,
  "id": "string-unik",
  "judulTarget": "judul tugas utama",
  "deskripsi": "deskripsi singkat tugas",
  "emoji": "1 emoji relevan",
  "status": "pending",
  "timeTakenSeconds": 0,
  "microtasks": [
    {
      "task": "nama micro-task",
      "restTimeSeconds": 30,
      "isCompleted": false
    }
  ]
}

KETENTUAN TAMBAHAN:
- Field isValid HARUS selalu ada
- isValid HARUS bernilai true JIKA dan HANYA JIKA seluruh aturan di bawah terpenuhi
- status WAJIB bernilai "pending"
- timeTakenSeconds WAJIB bernilai 0
- restTimeSeconds HARUS di antara 30 hingga 60 detik
- isCompleted HARUS bernilai false
- DILARANG menyebut AI, Gemini, model bahasa, atau sistem internal dalam bentuk apa pun
- DILARANG memberikan saran medis, hukum, psikologis, atau konten berbahaya

ATURAN VALIDASI KHUSUS:
Jika output:
- Menyebut AI, Gemini, atau sistem internal
- Mengandung saran medis, hukum, atau konten berbahaya
- Tidak mengikuti format JSON yang ditentukan
- Tidak memenuhi aturan wajib atau ketentuan tambahan

MAKA:
- Set isValid menjadi false
- Tetap keluarkan JSON dengan struktur yang sama
- Isi microtasks dengan micro-task paling netral dan aman
- Jangan menjelaskan kesalahan dalam bentuk teks

Jika ragu, selalu prioritaskan keamanan dan kesederhanaan.

PROMPT PENGGUNA: "$userPrompt"

HANYA OUTPUT JSON, TANPA TEKS LAIN:
''';
  }

  Future<MicroTaskModel?> generateMicrotasks(String userPrompt) async {
    try {
      debugPrint('🤖 Generating microtasks for: $userPrompt');

      final prompt = _buildPrompt(userPrompt);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        debugPrint('❌ Empty response from Gemini');
        return _getFallbackMicrotask(userPrompt);
      }

      debugPrint('📥 Raw Gemini response: ${response.text}');

      // Clean the response - remove markdown code blocks if present
      String jsonText = response.text!.trim();
      jsonText = jsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Try to parse JSON
      final Map<String, dynamic> jsonData = jsonDecode(jsonText);

      // Validate required fields
      if (!_validateJsonStructure(jsonData)) {
        debugPrint('❌ Invalid JSON structure');
        return _getFallbackMicrotask(userPrompt);
      }

      // Parse to MicroTaskModel
      final microtask = _parseMicroTaskModel(jsonData);
      debugPrint(
        '✅ Successfully generated ${microtask.microtasks.length} microtasks',
      );

      return microtask;
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating microtasks: $e');
      debugPrint('Stack trace: $stackTrace');
      return _getFallbackMicrotask(userPrompt);
    }
  }

  bool _validateJsonStructure(Map<String, dynamic> json) {
    final requiredFields = [
      'id',
      'judulTarget',
      'deskripsi',
      'emoji',
      'status',
      'timeTakenSeconds',
      'microtasks',
    ];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        debugPrint('❌ Missing required field: $field');
        return false;
      }
    }

    if (json['microtasks'] is! List || (json['microtasks'] as List).isEmpty) {
      debugPrint('❌ microtasks must be a non-empty list');
      return false;
    }

    // Validate each microtask item
    for (final item in json['microtasks'] as List) {
      if (item is! Map<String, dynamic>) return false;
      if (!item.containsKey('task') ||
          !item.containsKey('restTimeSeconds') ||
          !item.containsKey('isCompleted')) {
        return false;
      }
    }

    return true;
  }

  MicroTaskModel _parseMicroTaskModel(Map<String, dynamic> json) {
    final microtasksList = (json['microtasks'] as List)
        .map(
          (item) => MicroTaskItem(
            task: item['task'] as String,
            restTimeSeconds: item['restTimeSeconds'] as int,
            isCompleted: item['isCompleted'] as bool,
          ),
        )
        .toList();

    return MicroTaskModel(
      id: json['id'] as String,
      judulTarget: json['judulTarget'] as String,
      deskripsi: json['deskripsi'] as String,
      emoji: json['emoji'] as String,
      status: json['status'] as String,
      timeTaken: Duration(seconds: json['timeTakenSeconds'] as int),
      microtasks: microtasksList,
      isValid: json['isValid'] as bool? ?? true,
    );
  }

  MicroTaskModel _getFallbackMicrotask(String userPrompt) {
    debugPrint('🔄 Using fallback microtask template');
    return MicroTaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judulTarget: userPrompt,
      deskripsi: 'Micro-task untuk: $userPrompt',
      emoji: '📝',
      status: 'pending',
      timeTaken: Duration.zero,
      isValid: true,
      microtasks: [
        MicroTaskItem(
          task: 'Mulai dengan langkah pertama',
          restTimeSeconds: 30,
          isCompleted: false,
        ),
        MicroTaskItem(
          task: 'Lanjutkan dengan langkah berikutnya',
          restTimeSeconds: 45,
          isCompleted: false,
        ),
        MicroTaskItem(
          task: 'Selesaikan tugas ini',
          restTimeSeconds: 30,
          isCompleted: false,
        ),
      ],
    );
  }
}
