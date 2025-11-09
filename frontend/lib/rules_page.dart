import 'package:flutter/material.dart';
final TextEditingController _controller = TextEditingController();

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Custom Rules',
      ),
    );
  }
}