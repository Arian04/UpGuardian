import 'package:flutter/material.dart';

/// A page that shows a scalable 3-column table (Endpoint, Method, Body).
///
/// - Each row contains three editable fields (TextFields).
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
  bool saved;

  _RequestRow({String endpoint = '', String method = '', String body = '', bool saved = false})
      : endpointController = TextEditingController(text: endpoint),
        methodController = TextEditingController(text: method),
        bodyController = TextEditingController(text: body),
        saved = saved;

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

class _RequestsPageState extends State<RequestsPage> {
  // dynamic list of editable rows (controllers live here)
  final List<_RequestRow> rows = [];

  // saved requests: each entry is a map with keys: endpoint, method, body
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
    if (row.endpointController.text.trim().isEmpty &&
        row.methodController.text.trim().isEmpty &&
        row.bodyController.text.trim().isEmpty) {
      // don't save empty rows; just mark as saved to avoid duplicate saves
      setState(() => row.saved = true);
      return;
    }

    final map = row.values();
    setState(() {
      savedRequests.add(map);
      row.saved = true;
    });
  }

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
          Expanded(flex: 4, child: Text('Body', style: TextStyle(fontWeight: FontWeight.bold))),
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
          Expanded(flex: 4, child: Text(r.bodyController.text)),
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
          flex: 4,
          child: TextField(
            controller: r.bodyController,
            decoration: const InputDecoration(hintText: 'Request body'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => saveRow(index),
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
            // small footer showing saved variables for debugging / visibility
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Saved requests: ${savedRequests.length}'),
                  if (savedRequests.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: savedRequests.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Chip(label: Text('${s['method']}: ${s['endpoint']}')),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addRow,
        child: const Icon(Icons.add),
        tooltip: 'Add row',
      ),
    );
  }
}