import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:yellow_admin/screens/categories_screen.dart';
import 'package:yellow_admin/widgets/CustomeTextAndBtns/custome_elevated_btn.dart';
import 'package:yellow_admin/widgets/CustomeTextAndBtns/custome_text.dart';

import '../Utils/colors.dart';
import '../controllers/auth_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText("HOME", fontWeight: FontWeight.bold),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: (){
authController.signOut();
          }, icon: Icon(Icons.logout))
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomElevatedButton(
                  onPressed: () {
                    // Handle order button press
                  },
                  text: "Ckeck Order",
                  backgroundColor: AppColors.primaryColor,
                ),
                CustomElevatedButton(
                  onPressed: () {
                    // Handle order button press
                  },
                  text: "Add Products",
                ),
              ],
            ),
            SizedBox(height: 15,),
            Divider(),
                        SizedBox(height: 15,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomElevatedButton(
                  onPressed: () {
                    // Handle order button press
                  },
                  text: "Add Banners",
                ),
                CustomElevatedButton(
                  onPressed: () {
                    // Handle order button press
                    Get.to(CategoriesScreen());
                  },
                  text: "Add Categories",
                  backgroundColor: AppColors.primaryColor,
                ),
                
              ],
            ),

          ],
        ),
      ),
    );
  }
}
