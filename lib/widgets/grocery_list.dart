import 'package:flutter/material.dart';

import 'package:shopping_list/data/dummy_items.dart';

 

class GroceryList extends StatelessWidget{

  const GroceryList({super.key});

  @override 

  Widget build(BuildContext context)

  {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: (){},
            icon: Icon(Icons.add_box))
        ],
      ),

      body:ListView.builder(

        itemCount:groceryItems.length,

        itemBuilder:(ctx, index)=>ListTile(

          leading: Container(

            width:24, 

            height:24,

            color:groceryItems[index].category.color,

          ),

          title: Text(groceryItems[index].name), 

          trailing: Text(groceryItems[index].quantity.toString())

        ) ,

      )

    );

  }

}