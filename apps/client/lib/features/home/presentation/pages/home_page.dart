import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cordly_client/features/execute/data/repositories/execution_repository.dart';
import 'package:cordly_client/core/providers/current_workspace_provider.dart';
import 'package:cordly_client/core/database/database.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(currentWorkspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Search (Ctrl+/)',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: workspaceAsync.when(
        data: (workspace) {
          if (workspace == null) {
            return _buildNoWorkspaceState(context, ref);
          }
          return _HomeContent(workspaceId: workspace.id);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNoWorkspaceState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No workspace found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Trigger create workspace dialog
            },
            child: const Text('Create Workspace'),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final String workspaceId;

  const _HomeContent({required this.workspaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayExecutionsAsync = ref.watch(todayExecutionsProvider(workspaceId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Header
        Text(
          _formatDate(DateTime.now()),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),

        // Execution Summary
        todayExecutionsAsync.when(
          data: (executions) => _buildSummaryCard(context, executions),
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Execution> executions) {
    final pending = executions.where((e) => e.status == 'pending').length;
    final completed = executions.where((e) => e.status == 'completed').length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(label: 'Pending', value: '$pending', color: Colors.orange),
                _StatItem(label: 'Done', value: '$completed', color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Simple provider to get today's data
final todayExecutionsProvider = FutureProvider.family<List<Execution>, String>((ref, workspaceId) {
  return ref.watch(executionRepositoryProvider).getTodayExecutions(workspaceId);
});

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
