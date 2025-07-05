import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/services/storage_service.dart';

class ApiService {
  final String _baseUrl = 'https://admin.bellamasala.it/api/v1';
  final String _secret = 'fe1ca9859cefff19959d57aadc17187e';
  final StorageService _storageService = StorageService();

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

  Future<Map<String, dynamic>> updateMenu(
      String menuId, XFile imageFile) async {
    final token = await _storageService.getToken();
    if (token == null) {
      return {'status': false, 'message': 'Not authenticated'};
    }

    final url = Uri.parse('$_baseUrl/admin/menus/$menuId');
    print('--- Menu Update Request ---');
    print('URL: $url');

    var request = http.MultipartRequest(
      'POST', // Using POST as it's a multipart request to update
      url,
    );

    request.headers.addAll({
      'Secret': _secret,
      'Authorization': 'Bearer $token',
      'Accept-Language': 'en',
      'Accept': 'application/json',
    });

    final imageBytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: imageFile.name,
    ));

    print('Headers: ${request.headers}');
    print('Body (form field): image=${imageFile.name} (${imageBytes.length} bytes)');

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: $responseData');
    print('--------------------------');

    return data;
  }
}
