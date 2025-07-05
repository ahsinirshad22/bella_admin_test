import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/services/storage_service.dart';

class ApiService {
  final String _baseUrl = 'https://admin.bellamasala.it/api/v1';
  final String _secret = 'fe1ca9859cefff19959d57aadc17187e';
  final StorageService _storageService = StorageService();
  // Pexels API Keys (Primary and Fallback)
  final List<String> _pexelsApiKeys = [
    'PltBlMEG3AC0WfGhQamOQn9JBNX2agZMt4ULXnw4iNWbDsSgUS7PjQOt',
    '1SlWemUz6KAndKpw8kk9I3kZ6LXN6lnDpe6RY20xdwRIjSsNV6K7w0iq'
  ];

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Secret': _secret,
        'Accept-Language': 'en',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'type': 'admin',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final token = data['data']['token'];
      await _storageService.saveToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> getMenus() async {
    final token = await _storageService.getToken();
    if (token == null) {
      return {'status': false, 'message': 'Not authenticated'};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/menus?per_page=300'),
      headers: {
        'Secret': _secret,
        'Authorization': 'Bearer $token',
        'Accept-Language': 'en',
        'Accept': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }

  Future<List<String>> searchPexelsImages(String query, int count) async {
    for (final apiKey in _pexelsApiKeys) {
      if (apiKey.isEmpty) continue;

      final response = await http.get(
        Uri.parse('https://api.pexels.com/v1/search?query=$query&per_page=$count'),
        headers: {'Authorization': apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['photos'] != null && data['photos'].isNotEmpty) {
          return (data['photos'] as List)
              .map((photo) => photo['src']['large'] as String)
              .toList();
        }
      } else {
        print('Pexels API key failed (status: ${response.statusCode}). Trying next key.');
      }
    }
    print('All Pexels API keys failed.');
    return [];
  }

  Future<String?> searchPexelsImage(String query) async {
    final results = await searchPexelsImages(query, 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>> updateMenu(
      String menuId, XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    return updateMenuFromBytes(menuId, imageBytes, imageFile.name);
  }

  Future<Map<String, dynamic>> updateMenuFromBytes(
      String menuId, Uint8List imageBytes, String filename) async {
    final token = await _storageService.getToken();
    if (token == null) {
      return {'status': false, 'message': 'Not authenticated'};
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/admin/menus/$menuId'),
    );

    request.headers.addAll({
      'Secret': _secret,
      'Authorization': 'Bearer $token',
      'Accept-Language': 'en',
      'Accept': 'application/json',
    });

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
    ));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return jsonDecode(responseData);
  }
}
