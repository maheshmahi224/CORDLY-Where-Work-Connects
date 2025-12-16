// ============================================
// CORDLY Shared Constants
// ============================================

export const APP_NAME = 'CORDLY';
export const APP_TAGLINE = 'Where Work Connects';

// ----------------------
// Execution Defaults
// ----------------------
export const EXECUTION_TYPES = ['task', 'habit', 'event'] as const;
export const EXECUTION_STATUSES = ['pending', 'in_progress', 'completed', 'missed', 'skipped'] as const;

// ----------------------
// Workspace Roles
// ----------------------
export const WORKSPACE_ROLES = ['owner', 'editor', 'viewer'] as const;

// ----------------------
// Free Tier Limits (CRITICAL)
// ----------------------
export const FREE_TIER_LIMITS = {
    MAX_WORKSPACES_PER_USER: 3,
    MAX_EXECUTIONS_PER_WORKSPACE: 1000,
    MAX_PEOPLE_PER_WORKSPACE: 500,
    AI_CALLS_PER_DAY: 50,
    EXECUTION_LOG_RETENTION_DAYS: 90, // Archive after this
} as const;

// ----------------------
// AI Settings
// ----------------------
export const AI_CONFIG = {
    MODEL: 'gemini-1.5-flash', // Use flash for cost efficiency
    MAX_TOKENS_PER_REQUEST: 1024,
    RATE_LIMIT_WINDOW_MS: 60 * 1000, // 1 minute
    RATE_LIMIT_MAX_REQUESTS: 5,
} as const;
