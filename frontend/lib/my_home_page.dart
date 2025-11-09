import 'package:flutter/material.dart';

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
            Text('API Changes', style: theme.textTheme.titleLarge),
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
                icon: Icon(Icons.api_outlined),
                selectedIcon: Icon(Icons.api),
                label: Text('API Changes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule),
                label: Text('Rules'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: Text('Tests'),
              ),
            ],
          ),

          // Divider
          VerticalDivider(width: 1, color: theme.dividerColor),

          // Main content
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Repo selector + quick actions
                  Row(
                    children: [
                      // Repo dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.book, size: 18),
                            const SizedBox(width: 8),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRepo,
                                dropdownColor: surface,
                                style: TextStyle(color: textColor),
                                items: _repos
                                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedRepo = v ?? _selectedRepo),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Branch chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.call_split, size: 18),
                            SizedBox(width: 8),
                            Text('main'),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Action buttons
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Create Rule'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: const Text('Import'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Toolbar tabs and filter row
                  Row(
                    children: [
                      // Tabs
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildTab(context, 'Changes', true),
                            _buildTab(context, 'Diffs', false),
                            _buildTab(context, 'Settings', false),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Search / filter
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, size: 16),
                              SizedBox(width: 8),
                              Expanded(child: TextField(decoration: InputDecoration.collapsed(hintText: 'Search changes...'))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Toggle button
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filters',
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Main two-column content: list of changes + detail panel
                  Expanded(
                    child: Row(
                      children: [
                        // Changes list
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('API Changes', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: 8,
                                    separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                                    itemBuilder: (context, index) {
                                      final isSelected = index == _selectedChangeIndex;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: theme.colorScheme.primary.withOpacity(0.12),
                                        title: Text('Removed endpoint GET /v1/users/$index', style: TextStyle(color: textColor)),
                                        subtitle: Text('Breaking change: response schema changed', style: TextStyle(color: textColor.withOpacity(0.8))),
                                        trailing: Icon(Icons.chevron_right, color: textColor),
                                        onTap: () => setState(() => _selectedChangeIndex = index),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Details panel
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Change details', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Removed endpoint: GET /v1/users/$_selectedChangeIndex', style: theme.textTheme.titleSmall),
                                        const SizedBox(height: 8),
                                        Text('Description', style: theme.textTheme.bodyLarge),
                                        const SizedBox(height: 6),
                                        Text(
                                          'This endpoint was removed in favor of the new /v2/users endpoint. Clients relying on it should migrate to the new path. The response schema has also changed and requires updating the deserialization logic.',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Suggested fix', style: theme.textTheme.bodyLarge),
                                        const SizedBox(height: 6),
                                        Text('- Update client to call /v2/users\n- Update parsing to handle the new `items` array', style: theme.textTheme.bodyMedium),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {},
                                              child: const Text('Create PR'),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () {},
                                              child: const Text('Ignore'),
                                            ),
                                            const Spacer(),
                                            Text('Severity: High', style: TextStyle(color: theme.colorScheme.secondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, bool active) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: active ? Colors.white : theme.colorScheme.onSurface)),
    );
  }
}

