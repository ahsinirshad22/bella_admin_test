import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/models/menu_item.dart';
import 'package:untitled1/screens/menu_update_screen.dart';
import 'package:untitled1/services/api_service.dart';
import 'package:untitled1/widgets/cross_platform_image.dart';

class MenuActionsScreen extends StatefulWidget {
  final MenuItem menuItem;

  const MenuActionsScreen({super.key, required this.menuItem});

  @override
  State<MenuActionsScreen> createState() => _MenuActionsScreenState();
}

class _MenuActionsScreenState extends State<MenuActionsScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  final _urlController = TextEditingController();
  Future<List<String>>? _imageUrlsFuture;
  bool _isUpdating = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.menuItem.title;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _searchImages() {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      _imageUrlsFuture = _apiService.searchPexelsImages(
        _searchController.text.trim(),
        6,
      );
    });
  }

  void _navigateToManualUpdate() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MenuUpdateScreen(menuId: widget.menuItem.id.toString()),
    ));
  }

  Future<void> _downloadAndUploadImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL.')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
      _downloadProgress = 0.0;
    });

    try {
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(proxyUrl));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength;
        List<int> bytes = [];
        int receivedBytes = 0;

        await for (var chunk in response.stream) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes != null) {
            setState(() {
              _downloadProgress = receivedBytes / totalBytes;
            });
          } else {
            if (_downloadProgress != null) {
              setState(() => _downloadProgress = null);
            }
          }
        }

        setState(() => _downloadProgress = null);

        final imageBytes = Uint8List.fromList(bytes);
        final result = await _apiService.updateMenuFromBytes(
          widget.menuItem.id.toString(),
          imageBytes,
          '${widget.menuItem.id}.jpg',
        );

        if (result['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully!')),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Failed to update: ${result['message']}');
        }
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
        _downloadProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItem.title),
        actions: [
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              ),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isUpdating,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[ID: ${widget.menuItem.id}] ${widget.menuItem.title}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(widget.menuItem.description),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Manually'),
                    onPressed: _navigateToManualUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Or update from URL:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Update from URL'),
                    onPressed: () => _downloadAndUploadImage(_urlController.text),
                  ),
                ),
                if (_isUpdating)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _downloadProgress != null
                              ? 'Downloading... ${(_downloadProgress! * 100).toStringAsFixed(0)}%'
                              : 'Uploading...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _downloadProgress,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Or search for a suggestion on Pexels:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Image Search Query',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.search),
                      onPressed: _searchImages,
                      tooltip: 'Search',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<String>>(
                  future: _imageUrlsFuture,
                  builder: (context, snapshot) {
                    if (_imageUrlsFuture == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.0),
                          child: Text(
                            'Press the search button to find images.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Could not load suggested images. Please try a different search term or use one of the manual update options.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      );
                    }
                    final imageUrls = snapshot.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = imageUrls[index];
                        return GestureDetector(
                          onTap: () => _downloadAndUploadImage(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CrossPlatformImage(url: url),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
