import 'package:flutter/material.dart';

/// A page that shows a scalable 5-column table (Endpoints, Methods, Body, Old Response, New Response).
///
/// - Each row contains five editable fields (TextFields).
/// - Pressing Enter (submit) on any field will "save" that row: the values
///   are stored and the row becomes read-only text.
/// - The "+" button adds another editable row to the table.
/// - All saved rows' values are kept in `savedRequests` as maps and each row's
///   controllers are kept in `rows` while editing.

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestRow {
  TextEditingController endpointController;
  TextEditingController methodController;
  TextEditingController bodyController;
  TextEditingController oldResponseController;
  TextEditingController newResponseController;
  bool saved = false;

  _RequestRow({String endpoint = '', String method = '', String body = '', String oldResponse = '', String newResponse = ''})
      : endpointController = TextEditingController(text: endpoint),
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

class _RequestsPageState extends State<RequestsPage> {
  // dynamic list of editable rows (controllers live here)
  final List<_RequestRow> rows = [];

  // saved requests: each entry is a map with keys: endpoint, method, body, oldResponse, newResponse
  final List<Map<String, String>> savedRequests = [];

  @override
  void initState() {
    super.initState();
    // start with a single editable row
    rows.add(_RequestRow());
  }

  @override
  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
    super.dispose();
  }

  void addRow() {
    setState(() {
      rows.add(_RequestRow());
    });
  }

  void saveRow(int index) {
    final row = rows[index];
    final missing = <String>[];
    if (row.endpointController.text.trim().isEmpty) missing.add('Endpoint');
    if (row.methodController.text.trim().isEmpty) missing.add('Method');
    // Body is optional for requests table (same behaviour as rules table)
    if (row.oldResponseController.text.trim().isEmpty) missing.add('Old Response');
    if (row.newResponseController.text.trim().isEmpty) missing.add('New Response');

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
    // Dispose controllers for that row
    row.dispose();
    setState(() {
      rows.removeAt(index);
      if (wasSaved) {
        // remove first matching saved request (match by values)
        final found = savedRequests.indexWhere((m) =>
            m['endpoint'] == values['endpoint'] &&
            m['method'] == values['method'] &&
            m['oldResponse'] == values['oldResponse'] &&
            m['newResponse'] == values['newResponse']);
        if (found != -1) savedRequests.removeAt(found);
      }
      // keep at least one editable row so UI stays usable
      if (rows.isEmpty) rows.add(_RequestRow());
    });
  }
  // (Only removeRow exists now — it deletes both the row and the saved request if present.)

  Widget _buildHeader() {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Endpoint', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 2, child: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 3, child: Text('Body', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 3, child: Text('Old Response', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          Expanded(flex: 3, child: Text('New Response', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 12),
          SizedBox(width: 40, child: Center(child: Text(''))),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final r = rows[index];
    // If saved, show text; otherwise show TextFields
    if (r.saved) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
        child: Row(children: [
          Expanded(flex: 3, child: Text(r.endpointController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(r.methodController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(r.bodyController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(r.oldResponseController.text)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(r.newResponseController.text)),
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

    // editable
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
          flex: 3,
          child: TextField(
            controller: r.bodyController,
            decoration: const InputDecoration(hintText: 'Request body (optional)'),
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
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _buildRow(i),
              ),
            ),
            // banner removed: only FAB remains at bottom
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