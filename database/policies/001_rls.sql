-- ============================================
-- CORDLY Row Level Security (RLS) Policies
-- CRITICAL: These enforce data isolation
-- ============================================

-- Enable RLS on all tables
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE execution_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE consistency_scores ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION: Check workspace membership
-- ============================================
CREATE OR REPLACE FUNCTION is_workspace_member(ws_id UUID, min_role workspace_role DEFAULT 'viewer')
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM workspace_members
        WHERE workspace_id = ws_id
        AND user_id = auth.uid()
        AND (
            role = 'owner' OR
            (min_role = 'editor' AND role IN ('owner', 'editor')) OR
            (min_role = 'viewer') -- Viewer can be any role
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- WORKSPACES POLICIES
-- ============================================
-- Users can only see workspaces they are members of
CREATE POLICY "Users can view their workspaces"
    ON workspaces FOR SELECT
    USING (is_workspace_member(id));

-- Only owners can create workspaces (they become owner)
CREATE POLICY "Authenticated users can create workspaces"
    ON workspaces FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Only owners can update workspace settings
CREATE POLICY "Owners can update their workspaces"
    ON workspaces FOR UPDATE
    USING (owner_id = auth.uid());

-- Only owners can delete workspaces
CREATE POLICY "Owners can delete their workspaces"
    ON workspaces FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- WORKSPACE MEMBERS POLICIES
-- ============================================
CREATE POLICY "Members can view workspace members"
    ON workspace_members FOR SELECT
    USING (is_workspace_member(workspace_id));

-- Only owners can add members
CREATE POLICY "Owners can add members"
    ON workspace_members FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM workspaces
            WHERE id = workspace_id AND owner_id = auth.uid()
        )
    );

-- Only owners can update member roles
CREATE POLICY "Owners can update member roles"
    ON workspace_members FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM workspaces
            WHERE id = workspace_id AND owner_id = auth.uid()
        )
    );

-- Only owners can remove members
CREATE POLICY "Owners can remove members"
    ON workspace_members FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM workspaces
            WHERE id = workspace_id AND owner_id = auth.uid()
        )
    );

-- ============================================
-- EXECUTIONS POLICIES
-- ============================================
CREATE POLICY "Members can view executions"
    ON executions FOR SELECT
    USING (is_workspace_member(workspace_id));

CREATE POLICY "Editors can create executions"
    ON executions FOR INSERT
    WITH CHECK (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can update executions"
    ON executions FOR UPDATE
    USING (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can delete executions"
    ON executions FOR DELETE
    USING (is_workspace_member(workspace_id, 'editor'));

-- ============================================
-- EXECUTION LOGS POLICIES
-- ============================================
CREATE POLICY "Members can view execution logs"
    ON execution_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM executions
            WHERE executions.id = execution_logs.execution_id
            AND is_workspace_member(executions.workspace_id)
        )
    );

CREATE POLICY "Editors can create execution logs"
    ON execution_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM executions
            WHERE executions.id = execution_logs.execution_id
            AND is_workspace_member(executions.workspace_id, 'editor')
        )
    );

-- ============================================
-- PEOPLE POLICIES
-- ============================================
CREATE POLICY "Members can view people"
    ON people FOR SELECT
    USING (is_workspace_member(workspace_id));

CREATE POLICY "Editors can create people"
    ON people FOR INSERT
    WITH CHECK (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can update people"
    ON people FOR UPDATE
    USING (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can delete people"
    ON people FOR DELETE
    USING (is_workspace_member(workspace_id, 'editor'));

-- ============================================
-- NOTES POLICIES
-- ============================================
CREATE POLICY "Members can view notes"
    ON notes FOR SELECT
    USING (is_workspace_member(workspace_id));

CREATE POLICY "Editors can create notes"
    ON notes FOR INSERT
    WITH CHECK (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can update notes"
    ON notes FOR UPDATE
    USING (is_workspace_member(workspace_id, 'editor'));

CREATE POLICY "Editors can delete notes"
    ON notes FOR DELETE
    USING (is_workspace_member(workspace_id, 'editor'));

-- ============================================
-- DAILY INSIGHTS POLICIES
-- ============================================
CREATE POLICY "Members can view daily insights"
    ON daily_insights FOR SELECT
    USING (is_workspace_member(workspace_id));

-- Only backend service role can create insights
CREATE POLICY "Service role can create insights"
    ON daily_insights FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ============================================
-- CONSISTENCY SCORES POLICIES
-- ============================================
CREATE POLICY "Members can view consistency scores"
    ON consistency_scores FOR SELECT
    USING (is_workspace_member(workspace_id));

-- Only backend service role can write scores
CREATE POLICY "Service role can create scores"
    ON consistency_scores FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can update scores"
    ON consistency_scores FOR UPDATE
    USING (auth.role() = 'service_role');
