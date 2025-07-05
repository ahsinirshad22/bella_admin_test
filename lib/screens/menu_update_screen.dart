import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/services/api_service.dart';
import 'package:untitled1/services/storage_service.dart';
import 'package:untitled1/screens/login_screen.dart';
import 'package:untitled1/screens/auto_update_screen.dart';
import 'package:untitled1/screens/menu_list_screen.dart';
import 'package:untitled1/widgets/cross_platform_image.dart';

class MenuUpdateScreen extends StatefulWidget {
  final String? menuId;
  const MenuUpdateScreen({super.key, this.menuId});

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

  @override
  void initState() {
    super.initState();
    if (widget.menuId != null) {
      _menuIdController.text = widget.menuId!;
    }
  }

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
            icon: const Icon(Icons.list_alt),
            tooltip: 'Menu Browser',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MenuListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Auto-Update All',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AutoUpdateScreen()),
              );
            },
          ),
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
                : CrossPlatformImage(url: _imageFile!.path, height: 400),
            const SizedBox(height: 20),
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
