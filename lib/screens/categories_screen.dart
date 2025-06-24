import 'package:flutter/material.dart';
import 'package:yellow_admin/Utils/colors.dart';
import 'package:yellow_admin/widgets/CustomeTextAndBtns/custome_text.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: CustomText(
          "Categories",
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(children: [
        Expanded(child: 
        ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
          return ListTile(
            title: Text("Category ${index + 1}"),
            subtitle: Text("Description of category ${index + 1}"),
            trailing: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Handle edit action
                  },
                ),
              ],
            ),
          );
        })),
      ],),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}
