import 'package:flutter/material.dart';

/// Replacement requests table with validation and missing-fields dialog.
///
/// This file is intentionally separate so `requests_page.dart` remains untouched.

class RequestsTablePage extends StatefulWidget {
  const RequestsTablePage({super.key});

  @override
  State<RequestsTablePage> createState() => _RequestsTablePageState();
}

class _RequestRowData {
  final TextEditingController endpointController;
  final TextEditingController methodController;
  final TextEditingController bodyController;
  bool saved = false;

  _RequestRowData({String endpoint = '', String method = '', String body = ''})
      : endpointController = TextEditingController(text: endpoint),
        methodController = TextEditingController(text: method),
        bodyController = TextEditingController(text: body);

  Map<String, String> values() => {
        'endpoint': endpointController.text,
        'method': methodController.text,
        'body': bodyController.text,
      };

  void dispose() {
    endpointController.dispose();
    methodController.dispose();
    bodyController.dispose();
  }
}

class _RequestsTablePageState extends State<RequestsTablePage> {
  final List<_RequestRowData> rows = [];
  final List<Map<String, String>> savedRequests = [];

  @override
  void initState() {
    super.initState();
    rows.add(_RequestRowData());
  }

@override
void dispose() {
  for (final r in rows) {
    r.dispose();
  }
  super.dispose();
}

  void addRow() => setState(() => rows.add(_RequestRowData()));

  void saveRow(int index) {
    final row = rows[index];
    final missing = <String>[];
    if (row.endpointController.text.trim().isEmpty) missing.add('Endpoint');
    if (row.methodController.text.trim().isEmpty) missing.add('Method');
    if (row.bodyController.text.trim().isEmpty) missing.add('Body');

    if (missing.isNotEmpty) {
      _showMissingFieldsDialog(missing);
      return;
    }

    setState(() {
      savedRequests.add(row.values());
      row.saved = true;
    });
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
        final found = savedRequests.indexWhere((m) =>
            m['endpoint'] == values['endpoint'] && m['method'] == values['method'] && m['body'] == values['body']);
        if (found != -1) savedRequests.removeAt(found);
      }
      if (rows.isEmpty) rows.add(_RequestRowData());
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

  Widget _header() => Container(
        color: Colors.black12,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(children: const [
          Expanded(flex: 3, child: Text('Endpoint', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 2, child: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 4, child: Text('Body', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          SizedBox(width: 40, child: Center(child: Text(''))),
        ]),
      );

  Widget _buildRow(int index) {
    final r = rows[index];
    if (r.saved) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
        child: Row(children: [
          Expanded(flex: 3, child: Text(r.endpointController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(r.methodController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text(r.bodyController.text)),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Delete row and request',
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
            controller: r.endpointController,
            decoration: const InputDecoration(hintText: 'Enter endpoint'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => saveRow(index),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: r.methodController,
            decoration: const InputDecoration(hintText: 'GET/POST'),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => saveRow(index),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: TextField(
            controller: r.bodyController,
            decoration: const InputDecoration(hintText: 'Request body'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => saveRow(index),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(Icons.delete, size: 20),
            tooltip: 'Delete row and request',
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
        child: Column(children: [
          _header(),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) => _buildRow(i),
            ),
          ),
          // banner removed: only FAB remains at bottom
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addRow,
        tooltip: 'Add row',
        child: const Icon(Icons.add),
      ),
    );
  }
}
