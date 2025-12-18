import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget{
  const NewItem({super.key});

  @override
  State<NewItem> createState(){
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem>{
  final _formKey = GlobalKey<FormState>();

  var _eneteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  static const String firebaseUrl = 
  'https://shopping-list-29a1c-default-rtdb.europe-west1.firebasedatabase.app/';

  
  Future<void> _saveItem() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    setState(() {
      _isSending = true;
    });

    final url = Uri.parse('$firebaseUrl/shopping-list.json');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _eneteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title,
        }),
      );

      if (!mounted) return;

      if (response.statusCode >= 400) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item.')),
        );
        return;
      }

      final resData = json.decode(response.body) as Map<String, dynamic>;
      final id = resData['name']; // ✅ Firebase 生成的 key

      Navigator.of(context).pop(
        GroceryItem(
          id: id,
          name: _eneteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error / wrong firebaseUrl.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(label: Text('Name')),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return "Must have a name between 2 and 50 characters long!";
                  }
                  return null;
                },
                onSaved: (value) => _eneteredName = value!.trim(),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      decoration: const InputDecoration(label: Text('Quantity')),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num <= 0) {
                          return 'Must be a valid, positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          _enteredQuantity = int.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration:
                          const InputDecoration(label: Text('Category')),
                      items: [
                        for (final entry in categories.entries)
                          DropdownMenuItem(
                            value: entry.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: entry.value.color,
                                ),
                                const SizedBox(width: 8),
                                Text(entry.value.title),
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                            setState(() {
                              _selectedCategory =
                                  categories[Categories.vegetables]!;
                              _enteredQuantity = 1;
                            });
                          },
                    child: const Text("Reset"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Add Item"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}