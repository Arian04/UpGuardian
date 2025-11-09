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
        return Center(child: Text('Overview', style: theme.textTheme.titleLarge));
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

