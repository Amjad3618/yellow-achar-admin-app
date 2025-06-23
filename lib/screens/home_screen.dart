import 'package:flutter/material.dart';
import 'package:yellow_admin/widgets/customeTextAndBtns/custome_elevated_btn.dart';
import 'package:yellow_admin/widgets/customeTextAndBtns/custome_text.dart';

import '../Utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText("HOME", fontWeight: FontWeight.bold),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
