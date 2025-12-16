import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cordly_client/core/database/database.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ExecutionRepository {
  final AppDatabase _db;

  ExecutionRepository(this._db);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------
  Stream<List<Execution>> watchByWorkspace(String workspaceId) {
    return _db.watchExecutionsByWorkspace(workspaceId);
  }

  Future<List<Execution>> getTodayExecutions(String workspaceId) {
    return _db.getTodayExecutions(workspaceId, DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------
  Future<void> createExecution({
    required String workspaceId,
    required String title,
    required String type, // 'task', 'habit', 'event'
    DateTime? scheduledAt,
    DateTime? deadlineAt,
    String? recurrence,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    // 1. Insert Local
    await _db.insertExecution(ExecutionsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      type: Value(type),
      status: const Value('pending'),
      scheduledAt: Value(scheduledAt),
      deadlineAt: Value(deadlineAt),
      recurrence: Value(recurrence),
      createdAt: Value(now),
      updatedAt: Value(now),
      synced: const Value(false),
    ));

    // 2. Queue Sync
    final syncData = jsonEncode({
      'id': id,
      'workspace_id': workspaceId,
      'title': title,
      'type': type,
      'scheduled_at': scheduledAt?.toIso8601String(),
    });

    await _db.addToSyncQueue(SyncQueueCompanion(
      targetTable: const Value('executions'),
      operation: const Value('create'),
      recordId: Value(id),
      data: Value(syncData),
      timestamp: Value(now),
    ));
  }

  Future<void> markAsCompleted(String id) async {
    // 1. Update Local
    final execution = (await (_db.select(_db.executions)
          ..where((t) => t.id.equals(id)))
        .getSingle());

    await _db.updateExecution(
      execution.toCompanion(true).copyWith(
            status: const Value('completed'),
            updatedAt: Value(DateTime.now()),
            synced: const Value(false),
          ),
    );

    // 2. Queue Sync
    await _db.addToSyncQueue(SyncQueueCompanion(
      targetTable: const Value('executions'),
      operation: const Value('update'),
      recordId: Value(id),
      data: Value(jsonEncode({'status': 'completed'})),
      timestamp: Value(DateTime.now()),
    ));
  }
}

// -----------------------------------------------------------------------------
// Provider
// -----------------------------------------------------------------------------
final executionRepositoryProvider = Provider<ExecutionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExecutionRepository(db);
});
