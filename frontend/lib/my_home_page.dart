import 'package:flutter/material.dart';
import 'rules_page.dart';
import 'requests_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _selectedIndex = 1; // default to API Changes
  int _selectedChangeIndex = 0;

  // repository list removed (not used)

  // Controllers for landing page inputs
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _oldEndpointController = TextEditingController();
  final TextEditingController _newEndpointController = TextEditingController();

  // Temporary variables to store input
  String service = '';
  String oldEndpoint = '';
  String newEndpoint = '';

  @override
  void dispose() {
    _serviceController.dispose();
    _oldEndpointController.dispose();
    _newEndpointController.dispose();
    super.dispose();
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.code, size: 20),
            const SizedBox(width: 12),
            Text('UpGuardian', style: theme.textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Search changes',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left navigation rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: Text('Tests'),
              ),
                // Existing Requests button
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text('Requests'),
                ),
                // Replace the Tests icon/title with Rules icon/title
                NavigationRailDestination(
                  icon: Icon(Icons.rule_outlined),
                  selectedIcon: Icon(Icons.rule),
                  label: Text('Rules'),
                ),
                // end navigation destinations
            ],
          ),

          // Divider
          VerticalDivider(width: 1, color: theme.dividerColor),

          // Main content
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(18),
              child: _buildMainContent(theme, textColor, surface),
            ),
          ),
        ],
      ),
    );
  }

  // removed unused _buildTab helper

  Widget _buildMainContent(ThemeData theme, Color textColor, Color surface) {
    switch (_selectedIndex) {
      case 0:
        // Landing page: input for old/new service and endpoint
        final inputStyle = theme.textTheme.bodyLarge?.copyWith(color: textColor);
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('API Change Landing', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 18),
                Text('Service', style: inputStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    hintText: 'Enter service name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Old Endpoint', style: inputStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _oldEndpointController,
                  decoration: const InputDecoration(
                    hintText: 'Enter old endpoint (e.g. /v1/users)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Text('New Endpoint', style: inputStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _newEndpointController,
                  decoration: const InputDecoration(
                    hintText: 'Enter new endpoint (e.g. /v2/users)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    service = _serviceController.text.trim();
                    oldEndpoint = _oldEndpointController.text.trim();
                    newEndpoint = _newEndpointController.text.trim();
                    if (service.isEmpty || oldEndpoint.isEmpty || newEndpoint.isEmpty) {
                      _showAlert('All fields are required. Please fill out every field.');
                      return;
                    }
                    // You can use the variables here for further logic
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        );
      case 1:
        // simplified API Changes view (keeps repo selector and a change list)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // action row
            Row(
              children: [
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Create Rule')),
              ],
            ),
            const SizedBox(height: 12),
            // side-by-side: left = list, right = details for selected change
            Expanded(
              child: Row(
                children: [
                  // left: list of changes
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(12),
                      child: ListView.builder(
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedChangeIndex;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primary.withAlpha((0.12 * 255).round()),
                            title: Text('Removed endpoint GET /v1/users/$index', style: TextStyle(color: textColor)),
                            subtitle: Text('Breaking change: response schema changed', style: TextStyle(color: textColor.withAlpha((0.8 * 255).round()))),
                            trailing: Icon(Icons.chevron_right, color: textColor),
                            onTap: () => setState(() => _selectedChangeIndex = index),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // right: details panel for the selected change
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                      child: _buildChangeDetails(theme, textColor, _selectedChangeIndex),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
        // Requests page
        return const RequestsPage();
      case 3:
        // Rules page
        return const RulesPage();
      // removed Tests view (no longer a nav destination)
      default:
        return Center(child: Text('Unknown', style: theme.textTheme.titleLarge));
    }
  }

  // details panel for a selected change
  Widget _buildChangeDetails(ThemeData theme, Color textColor, int index) {
    // placeholder data — mirrors the list tile
    final title = 'Removed endpoint GET /v1/users/$index';
    final subtitle = 'Breaking change: response schema changed';
    const oldResponse = '{\n  "id": 1,\n  "name": "Alice"\n}';
    const newResponse = '{\n  "id": 1,\n  "fullName": "Alice Smith",\n  "active": true\n}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(color: textColor)),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: textColor.withAlpha((0.8 * 255).round()))),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Old response', style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(8)),
                        child: SingleChildScrollView(child: Text(oldResponse, style: const TextStyle(fontFamily: 'monospace'))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New response', style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(8)),
                        child: SingleChildScrollView(child: Text(newResponse, style: const TextStyle(fontFamily: 'monospace'))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Validate both old and new responses
                final oldErr = RulesPage.jsonValidationError(oldResponse);
                final newErr = RulesPage.jsonValidationError(newResponse);
                if (oldErr != null || newErr != null) {
                  final parts = <String>[];
                  if (oldErr != null) parts.add('Old response error: $oldErr');
                  if (newErr != null) parts.add('New response error: $newErr');
                  _showAlert(parts.join('\n'));
                  return;
                }
                // both valid
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Validation successful'),
                    content: const Text('Both old and new responses are valid JSON.'),
                    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Validate JSON'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('Accept change')),
            const SizedBox(width: 12),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.close), label: const Text('Ignore')),
          ],
        ),
      ],
    );
  }
}

