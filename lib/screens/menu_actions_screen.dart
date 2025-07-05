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
  late Future<List<String>> _imageUrlsFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final query = '${widget.menuItem.title} ${widget.menuItem.description}';
    _imageUrlsFuture = _apiService.searchPexelsImages(query, 6);
  }

  void _navigateToManualUpdate() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MenuUpdateScreen(menuId: widget.menuItem.id.toString()),
    ));
  }

  Future<void> _updateImage(String imageUrl) async {
    setState(() => _isUpdating = true);
    try {
      // A CORS proxy is still needed to download image bytes from Pexels on the web.
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
      final response = await http.get(Uri.parse(proxyUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final result = await _apiService.updateMenuFromBytes(
          widget.menuItem.id.toString(),
          imageBytes,
          '${widget.menuItem.id}.jpg',
        );

        if (result['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully!')),
          );
          Navigator.of(context).pop(true); // Pop with 'true' to signal a refresh
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
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItem.title),
      ),
      body: AbsorbPointer(
        absorbing: _isUpdating,
        child: Stack(
          children: [
            Padding(
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
                  const SizedBox(height: 24),
                  const Text(
                    'Or select a suggestion from Pexels:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<String>>(
                      future: _imageUrlsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Could not load suggested images from Pexels. Please use the manual update option.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          );
                        }
                        final imageUrls = snapshot.data!;
                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            final url = imageUrls[index];
                            return GestureDetector(
                              onTap: () => _updateImage(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CrossPlatformImage(url: url),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isUpdating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Updating...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
