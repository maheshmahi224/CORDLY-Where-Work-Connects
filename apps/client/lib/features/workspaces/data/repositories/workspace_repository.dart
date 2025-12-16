import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cordly_client/core/database/database.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class WorkspaceRepository {
  final AppDatabase _db;

  WorkspaceRepository(this._db);

  // ---------------------------------------------------------------------------
  // Reads (Directly from Local DB)
  // ---------------------------------------------------------------------------
  Stream<List<Workspace>> watchAll() {
    return _db.watchAllWorkspaces();
  }

  Future<List<Workspace>> getAll() {
    return _db.getAllWorkspaces();
  }

  // ---------------------------------------------------------------------------
  // Writes (Local DB + Sync Queue)
  // ---------------------------------------------------------------------------
  Future<void> createWorkspace(String name, String userId) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    // 1. Insert into Local DB
    await _db.insertWorkspace(WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      ownerId: Value(userId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // 2. Queue Sync Operation
    // Note: In a real implementation, we'd have a specialized SyncService to pick this up.
    // For now, we store the intent.
    final syncData = jsonEncode({
      'id': id,
      'name': name,
      'owner_id': userId,
    });

    await _db.addToSyncQueue(SyncQueueCompanion(
      targetTable: const Value('workspaces'),
      operation: const Value('create'),
      recordId: Value(id),
      data: Value(syncData),
      timestamp: Value(now),
    ));
  }
}

// -----------------------------------------------------------------------------
// Provider
// -----------------------------------------------------------------------------
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkspaceRepository(db);
});
