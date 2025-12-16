import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cordly_client/features/execute/data/repositories/execution_repository.dart';
import 'package:cordly_client/core/providers/current_workspace_provider.dart';
import 'package:cordly_client/core/database/database.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(currentWorkspaceProvider);

    return Scaffold(
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
          Icon(
            Icons.workspace_premium_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to CORDLY',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workspace to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // TODO: Open create workspace dialog
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Workspace'),
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
    final todayExecutionsAsync =
        ref.watch(todayExecutionsProvider(workspaceId));

    return CustomScrollView(
      slivers: [
        // Modern App Bar with Greeting
        SliverAppBar(
          floating: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Quick Stats Cards
              todayExecutionsAsync.when(
                data: (executions) => _buildStatsSection(context, executions),
                loading: () => _buildStatsLoading(context),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Weekly Progress Chart
              _buildWeeklyProgressCard(context),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsSection(context),

              const SizedBox(height: 24),

              // Today's Tasks
              todayExecutionsAsync.when(
                data: (executions) =>
                    _buildTodayTasksSection(context, executions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),

              // Activity Distribution Pie Chart
              _buildActivityDistributionCard(context),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good Morning';
    if (hour < 17) return '🌤️ Good Afternoon';
    return '🌙 Good Evening';
  }

  Widget _buildStatsSection(BuildContext context, List<Execution> executions) {
    final pending = executions.where((e) => e.status == 'pending').length;
    final completed = executions.where((e) => e.status == 'completed').length;
    final total = executions.length;
    final progress = total > 0 ? (completed / total * 100).round() : 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions,
            iconColor: Colors.orange,
            value: '$pending',
            label: 'Pending',
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            value: '$completed',
            label: 'Completed',
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            value: '$progress%',
            label: 'Progress',
            gradient: const LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsLoading(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} tasks',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _makeBarGroup(0, 5, 3),
                  _makeBarGroup(1, 7, 5),
                  _makeBarGroup(2, 4, 4),
                  _makeBarGroup(3, 8, 6),
                  _makeBarGroup(4, 6, 4),
                  _makeBarGroup(5, 3, 2),
                  _makeBarGroup(6, 2, 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                  color: Theme.of(context).colorScheme.primary, label: 'Total'),
              const SizedBox(width: 24),
              _LegendItem(color: Colors.green, label: 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double total, double completed) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          color: const Color(0xFF1A73E8),
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: completed,
          color: Colors.green,
          width: 12,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_task,
                label: 'Add Task',
                color: const Color(0xFF1A73E8),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.person_add_outlined,
                label: 'Add Person',
                color: const Color(0xFF34A853),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.event_outlined,
                label: 'New Event',
                color: const Color(0xFFEA4335),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.mic_outlined,
                label: 'Voice Note',
                color: const Color(0xFFFBBC04),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayTasksSection(
      BuildContext context, List<Execution> executions) {
    final pendingTasks =
        executions.where((e) => e.status == 'pending').take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Tasks",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pendingTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.celebration_outlined,
                    size: 48,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All tasks completed!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Great job! You\'re on fire 🔥',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          ...pendingTasks.map((task) => _TaskCard(execution: task)),
      ],
    );
  }

  Widget _buildActivityDistributionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: 40,
                    title: '40%',
                    color: const Color(0xFF1A73E8),
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: '30%',
                    color: const Color(0xFF34A853),
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: '20%',
                    color: const Color(0xFFFBBC04),
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 10,
                    title: '10%',
                    color: const Color(0xFFEA4335),
                    radius: 60,
                    titleStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendItem(color: Color(0xFF1A73E8), label: 'Tasks'),
              _LegendItem(color: Color(0xFF34A853), label: 'Meetings'),
              _LegendItem(color: Color(0xFFFBBC04), label: 'Habits'),
              _LegendItem(color: Color(0xFFEA4335), label: 'Events'),
            ],
          ),
        ],
      ),
    );
  }
}

// Simple provider to get today's data
final todayExecutionsProvider =
    FutureProvider.family<List<Execution>, String>((ref, workspaceId) {
  return ref.watch(executionRepositoryProvider).getTodayExecutions(workspaceId);
});

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: iconColor.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Execution execution;

  const _TaskCard({required this.execution});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  execution.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (execution.scheduledAt != null)
                  Text(
                    DateFormat('h:mm a').format(execution.scheduledAt!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          _getTypeChip(execution.type),
        ],
      ),
    );
  }

  Widget _getTypeChip(String type) {
    Color color;
    IconData icon;
    switch (type) {
      case 'task':
        color = const Color(0xFF1A73E8);
        icon = Icons.task_outlined;
        break;
      case 'habit':
        color = const Color(0xFF34A853);
        icon = Icons.loop;
        break;
      case 'event':
        color = const Color(0xFFEA4335);
        icon = Icons.event_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
