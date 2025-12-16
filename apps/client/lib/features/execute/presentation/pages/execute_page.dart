// ============================================
// Execute Page - Core Execution Engine
// ============================================
import 'package:flutter/material.dart';

class ExecutePage extends StatefulWidget {
  const ExecutePage({super.key});

  @override
  State<ExecutePage> createState() => _ExecutePageState();
}

class _ExecutePageState extends State<ExecutePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Execute'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Habits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildUpcomingTab(),
          _buildHabitsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExecutionSheet,
        tooltip: 'Add Execution',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    return _buildEmptyState(
      icon: Icons.check_circle_outline,
      title: 'No executions for today',
      subtitle: 'Tap + to add a task, habit, or event',
    );
  }

  Widget _buildUpcomingTab() {
    return _buildEmptyState(
      icon: Icons.upcoming_outlined,
      title: 'No upcoming executions',
      subtitle: 'Plan ahead by scheduling tasks and events',
    );
  }

  Widget _buildHabitsTab() {
    return _buildEmptyState(
      icon: Icons.repeat,
      title: 'No habits tracked',
      subtitle: 'Create recurring executions to build habits',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExecutionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddExecutionSheet(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _AddExecutionSheet extends StatefulWidget {
  const _AddExecutionSheet();

  @override
  State<_AddExecutionSheet> createState() => _AddExecutionSheetState();
}

class _AddExecutionSheetState extends State<_AddExecutionSheet> {
  final _titleController = TextEditingController();
  String _selectedType = 'task';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'New Execution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Type selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'task', label: Text('Task'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(value: 'habit', label: Text('Habit'), icon: Icon(Icons.repeat)),
              ButtonSegment(value: 'event', label: Text('Event'), icon: Icon(Icons.event)),
            ],
            selected: {_selectedType},
            onSelectionChanged: (selection) {
              setState(() => _selectedType = selection.first);
            },
          ),
          const SizedBox(height: 16),
          
          // Title input
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'What do you need to execute?',
              hintText: 'Enter title...',
            ),
          ),
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _createExecution,
                child: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _createExecution() {
    if (_titleController.text.trim().isEmpty) return;
    // TODO: Create execution via repository
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
