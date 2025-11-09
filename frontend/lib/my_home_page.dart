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

  final _repos = const [
    'arian04/upguardian',
    'example/repo',
  ];
  String _selectedRepo = 'arian04/upguardian';

  // Controllers for landing page inputs
  final TextEditingController _oldServiceController = TextEditingController();
  final TextEditingController _oldEndpointController = TextEditingController();
  final TextEditingController _newServiceController = TextEditingController();
  final TextEditingController _newEndpointController = TextEditingController();

  // Temporary variables to store input
  String oldService = '';
  String oldEndpoint = '';
  String newService = '';
  String newEndpoint = '';

  @override
  void dispose() {
    _oldServiceController.dispose();
    _oldEndpointController.dispose();
    _newServiceController.dispose();
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
                Text('Old Service', style: inputStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _oldServiceController,
                  decoration: const InputDecoration(
                    hintText: 'Enter old service name',
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
                Text('New Service', style: inputStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _newServiceController,
                  decoration: const InputDecoration(
                    hintText: 'Enter new service name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                    oldService = _oldServiceController.text.trim();
                    oldEndpoint = _oldEndpointController.text.trim();
                    newService = _newServiceController.text.trim();
                    newEndpoint = _newEndpointController.text.trim();
                    if (oldService.isEmpty || oldEndpoint.isEmpty || newService.isEmpty || newEndpoint.isEmpty) {
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
            // repo selector row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.book, size: 18),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRepo,
                        dropdownColor: surface,
                        style: TextStyle(color: textColor),
                        items: _repos.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => setState(() => _selectedRepo = v ?? _selectedRepo),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Create Rule')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
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
}

