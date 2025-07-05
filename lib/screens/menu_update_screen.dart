import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/services/api_service.dart';
import 'package:untitled1/services/storage_service.dart';
import 'package:untitled1/screens/login_screen.dart';

class MenuUpdateScreen extends StatefulWidget {
  const MenuUpdateScreen({super.key});

  @override
  State<MenuUpdateScreen> createState() => _MenuUpdateScreenState();
}

class _MenuUpdateScreenState extends State<MenuUpdateScreen> {
  final _menuIdController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;

  void _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _updateMenu() async {
    if (_menuIdController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a menu ID and an image.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.updateMenu(
      _menuIdController.text,
      _imageFile!,
    );

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Operation failed')),
    );

    if (result['status'] == true) {
       setState(() {
        _imageFile = null;
        _menuIdController.clear();
      });
    }

  }

  void _logout() async {
    await _storageService.clearToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _menuIdController,
              decoration: const InputDecoration(labelText: 'Menu ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _imageFile == null
                ? const Text('No image selected.')
                : kIsWeb
                    ? Image.network(_imageFile!.path, height: 200)
                    : Image.file(File(_imageFile!.path), height: 200),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateMenu,
                    child: const Text('Update Menu'),
                  ),
          ],
        ),
      ),
    );
  }
}
