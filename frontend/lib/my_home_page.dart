import 'package:flutter/material.dart';

import 'api/database.dart';
import 'api/services.dart';
import 'requests_page.dart';
import 'rules_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1; // default to API Changes
  int _selectedChangeIndex = 0;

  // repository list removed (not used)

  // Services loaded from the API
  final List<Service> _services = [];

  // which service is currently active (index into _services). -1 means none selected
  int _selectedServiceIndex = -1;

  late final UpGuardianAPI _api;
  bool _loadingServices = false;

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

  void _openAddServiceDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _buildAddServiceDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    _api = UpGuardianAPI();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
    });
    try {
      final list = await _api.listServices(UpGuardianAPI.profile);
      setState(() {
        _services.clear();
        _services.addAll(list);
        _selectedServiceIndex = _services.isNotEmpty ? 0 : -1;
      });
    } catch (e) {
      // show error and leave services empty
      _showAlert('Failed to load services: $e');
      setState(() {
        _services.clear();
        _selectedServiceIndex = -1;
      });
    } finally {
      setState(() {
        _loadingServices = false;
      });
    }
  }

  Widget _buildAddServiceDialog() {
    return AlertDialog(
      title: const Text('Add Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            const Text('Service'),
            const SizedBox(height: 6),
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                hintText: 'Enter service name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Old Endpoint'),
            const SizedBox(height: 6),
            TextField(
              controller: _oldEndpointController,
              decoration: const InputDecoration(
                hintText: 'Enter old endpoint (e.g. /v1/users)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('New Endpoint'),
            const SizedBox(height: 6),
            TextField(
              controller: _newEndpointController,
              decoration: const InputDecoration(
                hintText: 'Enter new endpoint (e.g. /v2/users)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final enteredService = _serviceController.text.trim();
            final enteredOld = _oldEndpointController.text.trim();
            final enteredNew = _newEndpointController.text.trim();
            if (enteredService.isEmpty ||
                enteredOld.isEmpty ||
                enteredNew.isEmpty) {
              _showAlert(
                'Service name, old endpoint and new endpoint are all required.',
              );
              return;
            }
            try {
              final navigator = Navigator.of(context);
              final created = await _api.createService(
                UpGuardianAPI.profile,
                enteredService,
                enteredOld,
                enteredNew,
              );
              if (!mounted) return;
              setState(() {
                _services.insert(0, created);
                _selectedServiceIndex = 0;
              });
              _serviceController.clear();
              _oldEndpointController.clear();
              _newEndpointController.clear();
              navigator.pop();
            } catch (e) {
              _showAlert('Failed to create service: $e');
            }
          },
          child: const Text('Add'),
        ),
      ],
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
            // show app name and active service
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UpGuardian', style: theme.textTheme.titleLarge),
                if (_selectedServiceIndex >= 0 &&
                    _selectedServiceIndex < _services.length)
                  Text(
                    _services[_selectedServiceIndex].name,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
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
        // Overview: list of known services and a button to add a new one (opens modal)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Services', style: theme.textTheme.headlineSmall),
                ElevatedButton.icon(
                  onPressed: _openAddServiceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loadingServices
                    ? const Center(child: CircularProgressIndicator())
                    : _services.isEmpty
                    ? Center(
                        child: Text(
                          'No services yet. Click "Add Service" to create one.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final svc = _services[index];
                          final isSelected = index == _selectedServiceIndex;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: theme.colorScheme.primary
                                  .withAlpha((0.12 * 255).round()),
                              title: Text(svc.name),
                              subtitle: Text(
                                '${svc.oldEndpoint} → ${svc.newEndpoint}',
                              ),
                              onTap: () => setState(() {
                                _selectedServiceIndex = index;
                              }),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final idToDelete = svc.id;
                                  try {
                                    await _api.deleteService(idToDelete);
                                    if (!mounted) return;
                                    setState(() {
                                      final removedIndex = _services.indexWhere(
                                        (s) => s.id == idToDelete,
                                      );
                                      if (removedIndex != -1) {
                                        _services.removeAt(removedIndex);
                                        // adjust selected index
                                        if (_services.isEmpty) {
                                          _selectedServiceIndex = -1;
                                        } else if (_selectedServiceIndex >=
                                            _services.length) {
                                          // if last item was removed, move selection to last
                                          _selectedServiceIndex =
                                              _services.length - 1;
                                        }
                                      }
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    _showAlert('Failed to delete service: $e');
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      case 1:
        // simplified API Changes view (keeps repo selector and a change list)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // action row
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Create Rule'),
                ),
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
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ListView.builder(
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedChangeIndex;

                          String title = "";
                          String subtitle = "";
                          switch (index) {
                            case 0:
                              title = 'GET /customers';
                              subtitle = 'Success';
                            case 1:
                              title = "POST /customers body={...}";
                              subtitle = "Failed: HTTP 400";
                          }
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primary
                                .withAlpha((0.12 * 255).round()),
                            title: Text(
                              title,
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: TextStyle(
                                color: textColor.withAlpha((0.8 * 255).round()),
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: textColor,
                            ),
                            onTap: () =>
                                setState(() => _selectedChangeIndex = index),
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
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _buildChangeDetails(
                        theme,
                        textColor,
                        'GET /customers',
                        'Success',
                      ),
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
        return Center(
          child: Text('Unknown', style: theme.textTheme.titleLarge),
        );
    }
  }

  // details panel for a selected change
  Widget _buildChangeDetails(
    ThemeData theme,
    Color textColor,
    String title,
    String subtitle,
  ) {
    // placeholder data — mirrors the list tile
    const oldResponse = """
    {
        "id": "0",
        "first_name": "john",
        "last_name": "doe",
        "street_address": "1111 SomePlace Lane",
        "created_at": "2025-11-09T02:07:10.131782",
        "last_login_at": "2025-11-09T02:07:10.131787"                                         
    }
    """;
    const newResponse = """
      {
          "id": "0",
          "first_name": "john",
          "last_name": "doe",
          "address": {
              "street_address": "1111 SomePlace Lane",
              "city": "dallas",
              "zip_code": 75080,
          },
          "created_at": "2025-11-09T02:09:10.062655",
          "last_login_at": "2025-11-09T02:09:10.062660",             
      }
    """;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor.withAlpha((0.8 * 255).round()),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Old response',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            oldResponse,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New response',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                    // const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            newResponse,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
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
                    content: const Text(
                      'Both old and new responses are valid JSON.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Validate JSON'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: const Text('Accept change'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.close),
              label: const Text('Ignore'),
            ),
          ],
        ),
      ],
    );
  }
}
