import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  var _isLoading = true; 
  String? _error;

  final String firebaseUrl = 'https://shopping-list-29a1c-default-rtdb.europe-west1.firebasedatabase.app/';

  
  @override
  void initState() {
    super.initState();
    _loadItems(); 
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse('$firebaseUrl/shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data.';
          _isLoading = false;
        });
        return;
      }

      if (response.body == 'null') {
        setState(() {
          _groceryItems.clear();
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);

      final loaded = <GroceryItem>[];

      for (final entry in data.entries) {
        final id = entry.key;
        final item = entry.value as Map<String, dynamic>;

        final categoryTitle = item['category'] as String;
        final category = categories.entries
            .firstWhere(
              (e) => e.value.title == categoryTitle,
              orElse: () => MapEntry(
                Categories.other,
                categories[Categories.other]!,
              ),
            )
            .value;

        loaded.add(
          GroceryItem(
            id: id,
            name: item['name'],
            quantity: item['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error / wrong firebaseUrl.';
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItem()),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  Future<void> _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    bool undone = false;

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${item.name}"'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            undone = true;
            setState(() {
              _groceryItems.insert(index, item);
            });
          },
        ),
      ),
    );

    await controller.closed;

    if (!mounted) return;
    if (undone) return;

    final url = Uri.parse('$firebaseUrl/shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (!mounted) return;

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Restored item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!));
    } else if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) {
          final item = _groceryItems[index];

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeItem(item),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete),
            ),
            child: ListTile(
              title: Text(item.name),
              leading: Container(
                width: 24,
                height: 24,
                color: item.category.color,
              ),
              trailing: Text(item.quantity.toString()),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add_box),
          ),
          IconButton(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
    );
  }
}