// ============================================
// Workspace Routes - Multi-tenancy
// ============================================
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { supabase } from '../index';

const router = Router();

// Validation schemas
const createWorkspaceSchema = z.object({
    name: z.string().min(1).max(100),
});

// GET /api/workspaces - Get user's workspaces
router.get('/', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { data, error } = await supabase
            .from('workspace_members')
            .select(`
        workspace_id,
        role,
        joined_at,
        workspaces (
          id,
          name,
          owner_id,
          created_at,
          updated_at
        )
      `)
            .eq('user_id', req.userId);

        if (error) {
            console.error('[Get Workspaces Error]', error);
            return res.status(500).json({ error: 'Failed to fetch workspaces' });
        }

        const workspaces = data.map((item: any) => ({
            ...item.workspaces,
            role: item.role,
            joined_at: item.joined_at,
        }));

        res.json({ workspaces });
    } catch (error) {
        console.error('[Get Workspaces Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/workspaces - Create workspace
router.post('/', requireAuth, validate(createWorkspaceSchema), async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { name } = req.body;

        // Create workspace
        const { data: workspace, error: workspaceError } = await supabase
            .from('workspaces')
            .insert({
                name,
                owner_id: req.userId,
            })
            .select()
            .single();

        if (workspaceError) {
            console.error('[Create Workspace Error]', workspaceError);
            return res.status(500).json({ error: 'Failed to create workspace' });
        }

        // Add creator as owner member
        const { error: memberError } = await supabase
            .from('workspace_members')
            .insert({
                workspace_id: workspace.id,
                user_id: req.userId,
                role: 'owner',
            });

        if (memberError) {
            console.error('[Add Member Error]', memberError);
            // Rollback workspace creation
            await supabase.from('workspaces').delete().eq('id', workspace.id);
            return res.status(500).json({ error: 'Failed to create workspace' });
        }

        res.status(201).json({ workspace });
    } catch (error) {
        console.error('[Create Workspace Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/workspaces/:id - Get workspace by ID
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        // Verify membership
        const { data: membership } = await supabase
            .from('workspace_members')
            .select('role')
            .eq('workspace_id', id)
            .eq('user_id', req.userId)
            .single();

        if (!membership) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const { data: workspace, error } = await supabase
            .from('workspaces')
            .select('*')
            .eq('id', id)
            .single();

        if (error || !workspace) {
            return res.status(404).json({ error: 'Workspace not found' });
        }

        res.json({ workspace, role: membership.role });
    } catch (error) {
        console.error('[Get Workspace Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;
