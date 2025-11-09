import 'package:flutter/material.dart';

/// Requests table adapted to behave like the rules table: 5 columns,
/// validation disallowing empty values except for Body.

class RequestsTablePage extends StatefulWidget {
  const RequestsTablePage({super.key});

  @override
  State<RequestsTablePage> createState() => _RequestsTablePageState();
}

class _RequestRowData {
  final TextEditingController endpointController;
  final TextEditingController methodController;
  final TextEditingController bodyController;
  final TextEditingController oldResponseController;
  final TextEditingController newResponseController;
  bool saved = false;

  _RequestRowData({
    String endpoint = '',
    String method = '',
    String body = '',
    String oldResponse = '',
    String newResponse = '',
  }) : endpointController = TextEditingController(text: endpoint),
       methodController = TextEditingController(text: method),
       bodyController = TextEditingController(text: body),
       oldResponseController = TextEditingController(text: oldResponse),
       newResponseController = TextEditingController(text: newResponse);

  Map<String, String> values() => {
    'endpoint': endpointController.text,
    'method': methodController.text,
    'body': bodyController.text,
    'oldResponse': oldResponseController.text,
    'newResponse': newResponseController.text,
  };

  void dispose() {
    endpointController.dispose();
    methodController.dispose();
    bodyController.dispose();
    oldResponseController.dispose();
    newResponseController.dispose();
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
    if (row.endpointController.text.trim().isEmpty) missing.add('Endpoints');
    if (row.methodController.text.trim().isEmpty) missing.add('Methods');
    // Body allowed to be empty
    if (row.oldResponseController.text.trim().isEmpty)
      missing.add('Old Response');
    if (row.newResponseController.text.trim().isEmpty)
      missing.add('New Response');

    if (missing.isNotEmpty) {
      _showMissingFieldsDialog(missing);
      return;
    }

    setState(() {
      savedRequests.add(row.values());
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
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
        final found = savedRequests.indexWhere(
          (m) =>
              m['endpoint'] == values['endpoint'] &&
              m['method'] == values['method'] &&
              m['body'] == values['body'] &&
              m['oldResponse'] == values['oldResponse'] &&
              m['newResponse'] == values['newResponse'],
        );
        if (found != -1) savedRequests.removeAt(found);
      }
      if (rows.isEmpty) rows.add(_RequestRowData());
    });
  }

  Widget _header() => Container(
    color: Colors.black12,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'Endpoints',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text('Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text('Body', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 12),
        Row(
          children: [
            SizedBox(
              // flex: 3,
              width: 100,
              child: Text(
                'Old Response',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // SizedBox(width: 12),
            SizedBox(
              // flex: 3,
              width: 100,
              child: Text(
                'New Response',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        // SizedBox(width: 12),
        // SizedBox(width: 40, child: Center(child: Text(''))),
      ],
    ),
  );

  Widget _buildRow(int index) {
    final r = rows[index];
    if (r.saved) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(r.endpointController.text)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: Text(r.methodController.text)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: Text(r.bodyController.text)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: Text(r.oldResponseController.text)),
            // const SizedBox(width: 12),
            Expanded(flex: 3, child: Text(r.newResponseController.text)),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Remove row',
                onPressed: () => removeRow(index),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
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
            flex: 3,
            child: TextField(
              controller: r.bodyController,
              decoration: const InputDecoration(hintText: 'Body (optional)'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => saveRow(index),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: r.oldResponseController,
              decoration: const InputDecoration(hintText: 'Old response'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => saveRow(index),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: r.newResponseController,
              decoration: const InputDecoration(hintText: 'New response'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => saveRow(index),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Remove row',
              onPressed: () => removeRow(index),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _buildRow(i),
              ),
            ),
            // no bottom banner; only FAB remains
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addRow,
        tooltip: 'Add row',
        child: const Icon(Icons.add),
      ),
    );
  }
}
