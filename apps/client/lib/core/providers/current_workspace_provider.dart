import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cordly_client/core/database/database.dart';
import 'package:cordly_client/features/workspaces/data/repositories/workspace_repository.dart';
import 'package:cordly_client/features/auth/data/repositories/auth_repository.dart';

// The ID of the currently selected workspace.
// Checks SharedPrefs in a real app, defaulting to null here.
final selectedWorkspaceIdProvider = StateProvider<String?>((ref) => null);

// The actual Workspace object.
final currentWorkspaceProvider = AsyncValueProvider<Workspace?>((ref) async {
  final selectedId = ref.watch(selectedWorkspaceIdProvider);
  final repository = ref.watch(workspaceRepositoryProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;

  if (user == null) return null;

  // Get all workspaces
  final workspaces = await repository.getAll();

  if (workspaces.isEmpty) {
    // If no workspaces exist, we might want to trigger a creation flow 
    // or return null to show a "Create Workspace" empty state.
    // For auto-onboarding, we could create a default one here.
    return null; 
  }

  // If ID is selected and valid, return it
  if (selectedId != null) {
    try {
      return workspaces.firstWhere((w) => w.id == selectedId);
    } catch (_) {
      // workspace might have been deleted
    }
  }

  // Default to the first one
  final first = workspaces.first;
  // Update state to match (fire and forget)
  Future.microtask(() => ref.read(selectedWorkspaceIdProvider.notifier).state = first.id);
  
  return first;
});

// Helper for AsyncValue
typedef AsyncValueProvider<T> = FutureProvider<T>;
