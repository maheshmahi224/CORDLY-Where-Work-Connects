// ============================================
// CORDLY App Shell - Adaptive Layout (Mobile/Web)
// ============================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Execute',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'People',
    ),
    NavigationDestination(
      icon: Icon(Icons.assistant_outlined),
      selectedIcon: Icon(Icons.assistant),
      label: 'Assistant',
    ),
  ];

  static const _routes = ['/home', '/execute', '/calendar', '/people', '/assistant'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexWhere((route) => location.startsWith(route));
    if (index != -1 && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      context.go(_routes[index]);
    }
  }

  // Keyboard shortcut handling
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Cmd/Ctrl + K for Command Palette
    if ((HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyK) {
      _showCommandPalette();
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl + 1-5 for quick navigation
    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.digit1) {
        _onDestinationSelected(0);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2) {
        _onDestinationSelected(1);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3) {
        _onDestinationSelected(2);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4) {
        _onDestinationSelected(3);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5) {
        _onDestinationSelected(4);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _showCommandPalette() {
    showDialog(
      context: context,
      builder: (context) => const CommandPaletteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar for wide screens (Web/Desktop)
            if (isWideScreen)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'CORDLY',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                destinations: _destinations
                    .map((d) => NavigationRailDestination(
                          icon: d.icon,
                          selectedIcon: d.selectedIcon,
                          label: Text(d.label),
                        ))
                    .toList(),
              ),
            
            // Vertical divider
            if (isWideScreen)
              const VerticalDivider(width: 1, thickness: 1),
            
            // Main content
            Expanded(child: widget.child),
          ],
        ),
        
        // Bottom navigation for narrow screens (Mobile)
        bottomNavigationBar: isWideScreen
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                destinations: _destinations,
                height: 65,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}

// ----------------------
// Command Palette (Cmd+K)
// ----------------------
class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  final _commands = [
    _Command('Go to Home', Icons.home, '/home'),
    _Command('Go to Execute', Icons.check_circle, '/execute'),
    _Command('Go to Calendar', Icons.calendar_today, '/calendar'),
    _Command('Go to People', Icons.people, '/people'),
    _Command('Go to Assistant', Icons.assistant, '/assistant'),
    _Command('New Task', Icons.add_task, 'action:new_task'),
    _Command('New Habit', Icons.repeat, 'action:new_habit'),
    _Command('New Event', Icons.event, 'action:new_event'),
    _Command('Add Person', Icons.person_add, 'action:add_person'),
  ];

  List<_Command> _filteredCommands = [];

  @override
  void initState() {
    super.initState();
    _filteredCommands = _commands;
    _focusNode.requestFocus();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = _commands;
      } else {
        _filteredCommands = _commands
            .where((cmd) => cmd.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _executeCommand(_Command cmd) {
    Navigator.of(context).pop();
    if (cmd.action.startsWith('/')) {
      context.go(cmd.action);
    } else {
      // TODO: Handle action commands
      debugPrint('Action: ${cmd.action}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Type a command...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1),
            // Command list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCommands.length,
                itemBuilder: (context, index) {
                  final cmd = _filteredCommands[index];
                  return ListTile(
                    leading: Icon(cmd.icon),
                    title: Text(cmd.label),
                    onTap: () => _executeCommand(cmd),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _Command {
  final String label;
  final IconData icon;
  final String action;

  const _Command(this.label, this.icon, this.action);
}
