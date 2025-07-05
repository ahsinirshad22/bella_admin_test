import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/services/api_service.dart';

enum LogLevel { info, success, error, warning }

class LogMessage {
  final String message;
  final LogLevel level;

  LogMessage(this.message, {this.level = LogLevel.info});
}

class AutoUpdateScreen extends StatefulWidget {
  const AutoUpdateScreen({super.key});

  @override
  State<AutoUpdateScreen> createState() => _AutoUpdateScreenState();
}

class _AutoUpdateScreenState extends State<AutoUpdateScreen> {
  final ApiService _apiService = ApiService();
  final List<LogMessage> _logs = [];
  bool _isUpdating = false;
  final ScrollController _scrollController = ScrollController();

  void _log(String message, {LogLevel level = LogLevel.info}) {
    setState(() {
      _logs.add(LogMessage(message, level: level));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _startAutoUpdate() async {
    setState(() {
      _isUpdating = true;
      _logs.clear();
    });

    _log('--- Starting Auto-Update Process ---');

    // 1. Fetch all menus
    _log('Step 1: Fetching all menus...');
    final menusResult = await _apiService.getMenus();

    if (menusResult['status'] == false) {
      _log('Error fetching menus: ${menusResult['message']}', level: LogLevel.error);
      _log(jsonEncode(menusResult), level: LogLevel.error);
      setState(() => _isUpdating = false);
      return;
    }
    _log('Successfully fetched menus.', level: LogLevel.success);
    _log(jsonEncode(menusResult['data']), level: LogLevel.info);

    final dynamic data = menusResult['data'];
    if (data == null || data['content'] == null || data['content'] is! List) {
      _log('No menus found or invalid data structure in response.', level: LogLevel.warning);
      _log('Full response: ${jsonEncode(menusResult)}', level: LogLevel.info);
      setState(() => _isUpdating = false);
      return;
    }

    final List<dynamic> menus = data['content'];
    _log('Found ${menus.length} menus to check.');

    // 2. Process each menu
    for (final menu in menus) {
      final String title = menu['title'];
      final int menuId = menu['id'];

      _log('---');
      _log('Processing "$title" (ID: $menuId)...');

      if (menu['image'] != null) {
        _log('  - Image already exists. Skipping.', level: LogLevel.warning);
        continue;
      }

      // 3. Find image on Pexels
      _log('  - No image found. Searching Pexels for: "$title"');
      final imageUrl = await _apiService.searchPexelsImage(title);

      if (imageUrl == null) {
        _log('  - Could not find a suitable image. Skipping.', level: LogLevel.warning);
        continue;
      }
      _log('  - Found image: $imageUrl', level: LogLevel.success);

      // 4. Download image
      _log('  - Downloading image...');
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          _log('  - Download complete.', level: LogLevel.success);
          final imageBytes = response.bodyBytes;

          // 5. Upload image
          _log('  - Uploading to server...');
          final uploadResult = await _apiService.updateMenuFromBytes(
            menuId.toString(),
            imageBytes,
            '$menuId.jpg',
          );

          if (uploadResult['status'] == true) {
            _log('  - Upload successful!', level: LogLevel.success);
            _log('  - Response: ${jsonEncode(uploadResult)}');
          } else {
            _log('  - Upload failed: ${uploadResult['message']}', level: LogLevel.error);
            _log('  - Response: ${jsonEncode(uploadResult)}', level: LogLevel.error);
          }
        } else {
          _log('  - Failed to download image. Status: ${response.statusCode}', level: LogLevel.error);
        }
      } catch (e) {
        _log('  - An error occurred: $e', level: LogLevel.error);
      }
    }

    _log('---');
    _log('Auto-update process finished.');
    setState(() => _isUpdating = false);
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.success:
        return Colors.green;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Update Menu Images'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _startAutoUpdate,
              child: _isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Start Auto-Update'),
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log.message,
                      style: TextStyle(color: _getLogColor(log.level)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
