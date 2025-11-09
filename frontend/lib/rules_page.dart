import 'package:flutter/material.dart';

/// Rules page with a 2-column table: Name | Expression
///
/// - Both columns are required when saving a row.
/// - The "+" FAB adds another editable row.
/// - Each row can be removed; removing a saved row also removes the
///   corresponding entry from `savedRules` (matching by name+expression).
class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RuleRow {
  final TextEditingController nameController;
  final TextEditingController exprController;
  bool saved = false;

  _RuleRow({String name = '', String expression = ''})
      : nameController = TextEditingController(text: name),
        exprController = TextEditingController(text: expression);

  Map<String, String> values() => {
        'name': nameController.text,
        'expression': exprController.text,
      };

  void dispose() {
    nameController.dispose();
    exprController.dispose();
  }
}

class _RulesPageState extends State<RulesPage> {
  final List<_RuleRow> rows = [];
  final List<Map<String, String>> savedRules = [];

  @override
  void initState() {
    super.initState();
    rows.add(_RuleRow());
  }

  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  void addRow() => setState(() => rows.add(_RuleRow()));

  void saveRow(int index) {
    final row = rows[index];
    final missing = <String>[];
    if (row.nameController.text.trim().isEmpty) missing.add('Name');
    if (row.exprController.text.trim().isEmpty) missing.add('Expression');

    if (missing.isNotEmpty) {
      _showMissingFieldsDialog(missing);
      return;
    }

    setState(() {
      savedRules.add(row.values());
      row.saved = true;
    });
  }

  void _showMissingFieldsDialog(List<String> missing) {
    final names = missing.join(', ');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Missing input'),
        content: Text('Please enter values for the following field(s): $names'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void removeRow(int index) {
    if (index < 0 || index >= rows.length) return;
    final row = rows[index];
    final wasSaved = row.saved;
    final values = row.values();
    row.dispose();
    setState(() {
      rows.removeAt(index);
      if (wasSaved) {
        final found = savedRules.indexWhere((m) =>
            m['name'] == values['name'] && m['expression'] == values['expression']);
        if (found != -1) savedRules.removeAt(found);
      }
      if (rows.isEmpty) rows.add(_RuleRow());
    });
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(children: const [
        Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(width: 12),
        Expanded(flex: 7, child: Text('Expression', style: TextStyle(fontWeight: FontWeight.bold))),
        SizedBox(width: 12),
        SizedBox(width: 40, child: Center(child: Text(''))),
      ]),
    );
  }

  Widget _buildRow(int index) {
    final r = rows[index];
    if (r.saved) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
        child: Row(children: [
          Expanded(flex: 3, child: Text(r.nameController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 7, child: Text(r.exprController.text)),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Remove rule',
              onPressed: () => removeRow(index),
            ),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: r.nameController,
            decoration: const InputDecoration(hintText: 'Rule name'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => saveRow(index),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 7,
          child: TextField(
            controller: r.exprController,
            decoration: const InputDecoration(hintText: 'Expression'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => saveRow(index),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(Icons.delete, size: 20),
            tooltip: 'Remove rule',
            onPressed: () => removeRow(index),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _buildRow(i),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addRow,
        tooltip: 'Add rule',
        child: const Icon(Icons.add),
      ),
    );
  }
}

