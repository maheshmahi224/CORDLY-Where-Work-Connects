// ============================================
// CORDLY Core Types - Source of Truth
// ============================================

// ----------------------
// User & Identity
// ----------------------
export interface User {
    id: string;
    email: string;
    created_at: string;
    updated_at: string;
}

// ----------------------
// Workspace & Membership
// ----------------------
export type WorkspaceRole = 'owner' | 'editor' | 'viewer';

export interface Workspace {
    id: string;
    name: string;
    owner_id: string;
    created_at: string;
    updated_at: string;
}

export interface WorkspaceMember {
    id: string;
    workspace_id: string;
    user_id: string;
    role: WorkspaceRole;
    joined_at: string;
}

// ----------------------
// Execution Engine (Core)
// ----------------------
export type ExecutionType = 'task' | 'habit' | 'event';
export type ExecutionStatus = 'pending' | 'in_progress' | 'completed' | 'missed' | 'skipped';
export type RecurrenceRule = 'daily' | 'weekly' | 'monthly' | 'custom' | null;

export interface Execution {
    id: string;
    workspace_id: string;
    title: string;
    purpose: string | null; // "Why" - the reason for this execution
    type: ExecutionType;
    status: ExecutionStatus;
    scheduled_at: string | null; // ISO timestamp
    deadline_at: string | null; // ISO timestamp
    recurrence: RecurrenceRule;
    recurrence_config: Record<string, unknown> | null; // Custom recurrence details (e.g., days of week)
    parent_execution_id: string | null; // For recurring instances
    created_at: string;
    updated_at: string;
}

export interface ExecutionLog {
    id: string;
    execution_id: string;
    status: ExecutionStatus;
    logged_at: string; // ISO timestamp
    notes: string | null;
}

// ----------------------
// Relationship Memory (People CRM)
// ----------------------
export type FollowUpStatus = 'none' | 'pending' | 'done';

export interface Person {
    id: string;
    workspace_id: string;
    name: string;
    role: string | null; // Job title
    company: string | null;
    linkedin_url: string | null;
    event_met: string | null; // Name of the event
    date_met: string | null; // ISO date
    location_met: string | null;
    tags: string[]; // e.g., ["investor", "india-trip", "2024"]
    notes: string | null;
    follow_up_status: FollowUpStatus;
    created_at: string;
    updated_at: string;
}

// ----------------------
// Notes (Contextual)
// ----------------------
export type NoteContextType = 'execution' | 'person' | 'day';

export interface Note {
    id: string;
    workspace_id: string;
    context_type: NoteContextType;
    context_id: string; // ID of Execution, Person, or Date string (YYYY-MM-DD)
    content: string; // Structured text (Markdown)
    created_at: string;
    updated_at: string;
}

// ----------------------
// AI / Analytics
// ----------------------
export interface DailyInsight {
    id: string;
    workspace_id: string;
    date: string; // YYYY-MM-DD
    summary: string;
    generated_at: string;
}

export interface ConsistencyScore {
    workspace_id: string;
    date: string; // YYYY-MM-DD
    score: number; // 0-100
    calculation_details: Record<string, unknown>;
}
