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
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Custom Rules',
      ),
    );
  }
}

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final rulesInput = TextEditingController();

  @override
  void dispose() {
    rulesInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: rulesInput);
  }
}