-- ============================================
-- CORDLY Database Schema
-- Core Tables for Supabase (PostgreSQL)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. WORKSPACES
-- ============================================
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for owner lookup
CREATE INDEX idx_workspaces_owner ON workspaces(owner_id);

-- ============================================
-- 2. WORKSPACE MEMBERS
-- ============================================
CREATE TYPE workspace_role AS ENUM ('owner', 'editor', 'viewer');

CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role workspace_role NOT NULL DEFAULT 'viewer',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workspace_id, user_id)
);

-- Indexes for membership lookups
CREATE INDEX idx_workspace_members_workspace ON workspace_members(workspace_id);
CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);

-- ============================================
-- 3. EXECUTIONS (Core Engine)
-- ============================================
CREATE TYPE execution_type AS ENUM ('task', 'habit', 'event');
CREATE TYPE execution_status AS ENUM ('pending', 'in_progress', 'completed', 'missed', 'skipped');
CREATE TYPE recurrence_rule AS ENUM ('daily', 'weekly', 'monthly', 'custom');

CREATE TABLE executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    purpose TEXT, -- "Why" for this execution
    type execution_type NOT NULL DEFAULT 'task',
    status execution_status NOT NULL DEFAULT 'pending',
    scheduled_at TIMESTAMPTZ,
    deadline_at TIMESTAMPTZ,
    recurrence recurrence_rule,
    recurrence_config JSONB, -- Custom recurrence details
    parent_execution_id UUID REFERENCES executions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_executions_workspace ON executions(workspace_id);
CREATE INDEX idx_executions_status ON executions(status);
CREATE INDEX idx_executions_scheduled ON executions(scheduled_at);
CREATE INDEX idx_executions_type ON executions(type);

-- ============================================
-- 4. EXECUTION LOGS
-- ============================================
CREATE TABLE execution_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES executions(id) ON DELETE CASCADE,
    status execution_status NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- Index for log retrieval
CREATE INDEX idx_execution_logs_execution ON execution_logs(execution_id);
CREATE INDEX idx_execution_logs_logged_at ON execution_logs(logged_at);

-- ============================================
-- 5. PEOPLE (Relationship Memory)
-- ============================================
CREATE TYPE follow_up_status AS ENUM ('none', 'pending', 'done');

CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT, -- Job title
    company TEXT,
    linkedin_url TEXT,
    event_met TEXT, -- Name of event where met
    date_met DATE,
    location_met TEXT,
    tags TEXT[] DEFAULT '{}',
    notes TEXT,
    follow_up_status follow_up_status DEFAULT 'none',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for search
CREATE INDEX idx_people_workspace ON people(workspace_id);
CREATE INDEX idx_people_name ON people(name);
CREATE INDEX idx_people_tags ON people USING GIN(tags);
CREATE INDEX idx_people_event_met ON people(event_met);
CREATE INDEX idx_people_date_met ON people(date_met);

-- ============================================
-- 6. NOTES (Contextual)
-- ============================================
CREATE TYPE note_context_type AS ENUM ('execution', 'person', 'day');

CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    context_type note_context_type NOT NULL,
    context_id TEXT NOT NULL, -- UUID for execution/person, YYYY-MM-DD for day
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for context lookup
CREATE INDEX idx_notes_workspace ON notes(workspace_id);
CREATE INDEX idx_notes_context ON notes(context_type, context_id);

-- ============================================
-- 7. DAILY INSIGHTS (AI Generated)
-- ============================================
CREATE TABLE daily_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    summary TEXT NOT NULL,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(workspace_id, date)
);

CREATE INDEX idx_daily_insights_workspace_date ON daily_insights(workspace_id, date);

-- ============================================
-- 8. CONSISTENCY SCORES
-- ============================================
CREATE TABLE consistency_scores (
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    calculation_details JSONB,
    PRIMARY KEY (workspace_id, date)
);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all relevant tables
CREATE TRIGGER update_workspaces_updated_at BEFORE UPDATE ON workspaces
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_executions_updated_at BEFORE UPDATE ON executions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_people_updated_at BEFORE UPDATE ON people
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
