//enum categories
import 'package:flutter/material.dart';

enum Categories{
  vegetables, 
  fruit,
  meat, 
  dairy, 
  carbs, 
  sweets, 
  spices, 
  convenience,
  hygiene, 
  other
}
//class cateogry
class Category{
  const Category(this.title, this.color);
  final String title;
  final Color color;
}