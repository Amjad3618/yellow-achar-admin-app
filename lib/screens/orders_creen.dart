import 'package:flutter/material.dart';

class OrdersCreen extends StatefulWidget {
  const OrdersCreen({super.key});

  @override
  State<OrdersCreen> createState() => _OrdersCreenState();
}

class _OrdersCreenState extends State<OrdersCreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}