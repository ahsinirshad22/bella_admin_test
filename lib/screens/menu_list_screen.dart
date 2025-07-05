import 'package:flutter/material.dart';
import 'package:untitled1/models/menu_item.dart';
import 'package:untitled1/screens/menu_actions_screen.dart';
import 'package:untitled1/services/api_service.dart';
import 'package:untitled1/widgets/cross_platform_image.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<MenuItem>> _menuItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  void _loadMenus() {
    setState(() {
      _menuItemsFuture = _apiService.getMenus().then((response) {
        if (response['status'] == true && response['data']?['content'] != null) {
          final List<dynamic> menuData = response['data']['content'];
          return menuData.map((json) => MenuItem.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load menus: ${response['message']}');
        }
      });
    });
  }

  void _navigateToMenuActions(MenuItem item) async {
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuActionsScreen(
          menuItem: item,
        ),
      ),
    );

    if (result == true) {
      _loadMenus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenus,
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menuItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }

          final menuItems = snapshot.data!;

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: item.imageUrl != null
                      ? CrossPlatformImage(
                          url: item.imageUrl!,
                          width: 100,
                          height: 100,
                        )
                      : const SizedBox(
                          width: 100,
                          height: 100,
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                  title: Text('[ID: ${item.id}] ${item.title}'),
                  subtitle: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _navigateToMenuActions(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
