import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../ai/models/ai_output.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your local network IP for real devices.
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> register(String email, String password, Map<String, dynamic> userData) async {
    final uri = Uri.parse('$baseUrl/register');
    var request = http.MultipartRequest('POST', uri);
    request.fields['email'] = email.trim();
    request.fields['password'] = password;
    request.fields['name'] = userData['name'].toString();
    request.fields['age'] = userData['age'].toString();
    request.fields['gender'] = userData['gender'].toString();
    request.fields['weight'] = userData['weight'].toString();
    request.fields['height'] = userData['height'].toString();
    request.fields['goal'] = userData['goal'].toString();

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final json = jsonDecode(responseData);
    
    if (response.statusCode == 200) {
      return json;
    } else {
      throw Exception(json['detail'] ?? 'Kayıt başarısız oldu.');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    var request = http.MultipartRequest('POST', uri);
    request.fields['email'] = email.trim().toLowerCase();
    request.fields['password'] = password;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final json = jsonDecode(responseData);
    
    if (response.statusCode == 200) {
      return json;
    } else {
      throw Exception(json['detail'] ?? 'Giriş başarısız oldu. Lütfen bilgilerinizi kontrol edin.');
    }
  }

  Future<AiOutput> analyzePhoto(XFile image, Map<String, dynamic> userData) async {
    final uri = Uri.parse('$baseUrl/analysis');
    var request = http.MultipartRequest('POST', uri);
    
    // Add the image file (web & mobile compatible)
    final bytes = await image.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: image.name,
      ),
    );
    
    // Add user data fields natively
    request.fields['userId'] = (userData['name'] ?? 'default_user').toString();
    request.fields['height'] = userData['height'].toString();
    request.fields['weight'] = userData['weight'].toString();
    request.fields['age'] = userData['age'].toString();
    request.fields['gender'] = userData['gender'].toString();
    request.fields['goal'] = userData['goal'].toString();

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final json = jsonDecode(responseData);
      if (json['error'] == 'invalid_photo') {
         throw const FormatException('invalid_photo');
      }
      return _mapJsonToAiOutput(json);
    } else {
      try {
        final json = jsonDecode(responseData);
         if (json['error'] == 'invalid_photo') {
           throw const FormatException('invalid_photo');
        }
      } catch (_) {}
      throw Exception('Failed to analyze photo: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final uri = Uri.parse('$baseUrl/analysis/history');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load history: ${response.statusCode}');
    }
  }

  AiOutput _mapJsonToAiOutput(Map<String, dynamic> json) {
     return AiOutput(
        landmarksDetected: true,
        bmi: json['bmi']?.toDouble() ?? 0.0,
        bodyFatPct: json['bodyFatPct']?.toDouble() ?? 0.0,
        leanMassKg: json['leanMassKg']?.toDouble() ?? 0.0,
        riskLevel: json['riskLevel'] ?? 'Normal',
        recommendations: AiRecommendations(
            dailyCalories: json['calories'] ?? json['recommendations']?['dailyCalories'] ?? 2000,
            macros: _parseMacros(json),
            dietPlan: _parseStringList(json, 'dietPlan'),
            workoutPlan: _parseStringList(json, 'workoutPlan'),
        ),
        debug: AiDebug(
            poseScore: 1.0, 
            qualityChecks: {'fullBodyVisible': true, 'poseOk': true}, 
            rawRatios: {}
        )
     );
  }

  Map<String, int> _parseMacros(Map<String, dynamic> json) {
    var source = json['macros'] ?? json['recommendations']?['macros'];
    if (source is Map) {
       return {
         'proteinPct': source['proteinPct'] ?? 30,
         'carbsPct': source['carbsPct'] ?? 40,
         'fatPct': source['fatPct'] ?? 30,
       };
    }
    return {'proteinPct': 30, 'carbsPct': 40, 'fatPct': 30};
  }

  List<String> _parseStringList(Map<String, dynamic> json, String key) {
    var list = json[key] ?? json['recommendations']?[key];
    if (list is List) {
      return List<String>.from(list);
    }
    return [];
  }
}
