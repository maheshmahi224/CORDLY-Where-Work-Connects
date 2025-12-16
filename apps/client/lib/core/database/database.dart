// ============================================
// Local Database - Drift Schema (Offline-First)
// ============================================
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

// ----------------------
// Tables
// ----------------------

// Workspaces
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text().named('owner_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// Executions
class Executions extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().named('workspace_id')();
  TextColumn get title => text()();
  TextColumn get purpose => text().nullable()();
  TextColumn get type => text()(); // 'task', 'habit', 'event'
  TextColumn get status => text()(); // 'pending', 'completed', etc.
  DateTimeColumn get scheduledAt =>
      dateTime().nullable().named('scheduled_at')();
  DateTimeColumn get deadlineAt => dateTime().nullable().named('deadline_at')();
  TextColumn get recurrence => text().nullable()();
  TextColumn get recurrenceConfig =>
      text().nullable().named('recurrence_config')(); // JSON string
  TextColumn get parentExecutionId =>
      text().nullable().named('parent_execution_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))(); // Sync status

  @override
  Set<Column> get primaryKey => {id};
}

// People
class People extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().named('workspace_id')();
  TextColumn get name => text()();
  TextColumn get role => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get linkedinUrl => text().nullable().named('linkedin_url')();
  TextColumn get eventMet => text().nullable().named('event_met')();
  TextColumn get dateMet => text().nullable().named('date_met')();
  TextColumn get locationMet => text().nullable().named('location_met')();
  TextColumn get tags => text().nullable()(); // JSON array as string
  TextColumn get notes => text().nullable()();
  TextColumn get followUpStatus =>
      text().withDefault(const Constant('none')).named('follow_up_status')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Notes
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().named('workspace_id')();
  TextColumn get contextType =>
      text().named('context_type')(); // 'execution', 'person', 'day'
  TextColumn get contextId => text().named('context_id')();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Queue for pending sync operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get recordId => text().named('record_id')();
  TextColumn get data => text()(); // JSON string
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0)).named('retry_count')();
}

// ----------------------
// Database
// ----------------------
@DriftDatabase(tables: [Workspaces, Executions, People, Notes, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cordly_local_db');
  }

  // ----------------------
  // Workspaces
  // ----------------------
  Future<List<Workspace>> getAllWorkspaces() => select(workspaces).get();

  Stream<List<Workspace>> watchAllWorkspaces() => select(workspaces).watch();

  Future<int> insertWorkspace(WorkspacesCompanion workspace) =>
      into(workspaces).insert(workspace);

  Future<void> deleteWorkspace(String id) =>
      (delete(workspaces)..where((t) => t.id.equals(id))).go();

  // ----------------------
  // Executions
  // ----------------------
  Future<List<Execution>> getExecutionsByWorkspace(String workspaceId) =>
      (select(executions)..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  Stream<List<Execution>> watchExecutionsByWorkspace(String workspaceId) =>
      (select(executions)..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  Future<List<Execution>> getTodayExecutions(
      String workspaceId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return (select(executions)
          ..where((t) =>
              t.workspaceId.equals(workspaceId) &
              ((t.scheduledAt.isBetweenValues(start, end)) |
                  (t.deadlineAt.isBetweenValues(start, end)))))
        .get();
  }

  Future<int> insertExecution(ExecutionsCompanion execution) =>
      into(executions).insert(execution);

  Future<bool> updateExecution(ExecutionsCompanion execution) =>
      update(executions).replace(execution as Execution);

  Future<void> deleteExecution(String id) =>
      (delete(executions)..where((t) => t.id.equals(id))).go();

  // ----------------------
  // People
  // ----------------------
  Future<List<PeopleData>> getPeopleByWorkspace(String workspaceId) =>
      (select(people)..where((t) => t.workspaceId.equals(workspaceId))).get();

  Stream<List<PeopleData>> watchPeopleByWorkspace(String workspaceId) =>
      (select(people)..where((t) => t.workspaceId.equals(workspaceId))).watch();

  Future<List<PeopleData>> searchPeople(String workspaceId, String query) =>
      (select(people)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                (t.name.contains(query) |
                    t.company.contains(query) |
                    t.eventMet.contains(query))))
          .get();

  Future<int> insertPerson(PeopleCompanion person) =>
      into(people).insert(person);

  Future<bool> updatePerson(PeopleCompanion person) =>
      update(people).replace(person as PeopleData);

  Future<void> deletePerson(String id) =>
      (delete(people)..where((t) => t.id.equals(id))).go();

  // ----------------------
  // Sync Queue
  // ----------------------
  Future<List<SyncQueueData>> getPendingSyncOperations() => (select(syncQueue)
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
      .get();

  Future<int> addToSyncQueue(SyncQueueCompanion operation) =>
      into(syncQueue).insert(operation);

  Future<void> clearSyncQueueItem(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();
}

// ----------------------
// Provider
// ----------------------
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
