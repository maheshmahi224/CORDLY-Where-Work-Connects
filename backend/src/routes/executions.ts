// ============================================
// Executions Routes - Core Execution Engine
// ============================================
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { supabase } from '../index';

const router = Router();

// Validation schemas
const createExecutionSchema = z.object({
    workspace_id: z.string().uuid(),
    title: z.string().min(1).max(500),
    purpose: z.string().optional(),
    type: z.enum(['task', 'habit', 'event']),
    scheduled_at: z.string().optional(),
    deadline_at: z.string().optional(),
    recurrence: z.enum(['daily', 'weekly', 'monthly', 'custom']).optional(),
    recurrence_config: z.record(z.unknown()).optional(),
});

const updateExecutionSchema = z.object({
    title: z.string().min(1).max(500).optional(),
    purpose: z.string().optional(),
    status: z.enum(['pending', 'in_progress', 'completed', 'missed', 'skipped']).optional(),
    scheduled_at: z.string().optional(),
    deadline_at: z.string().optional(),
});

// GET /api/executions?workspace_id=xxx&type=xxx&status=xxx
router.get('/', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { workspace_id, type, status, date } = req.query;

        if (!workspace_id) {
            return res.status(400).json({ error: 'workspace_id is required' });
        }

        let query = supabase
            .from('executions')
            .select('*')
            .eq('workspace_id', workspace_id as string)
            .order('created_at', { ascending: false });

        if (type) {
            query = query.eq('type', type as string);
        }

        if (status) {
            query = query.eq('status', status as string);
        }

        if (date) {
            // Filter by date (scheduled_at or deadline_at on specific day)
            const startOfDay = new Date(date as string);
            startOfDay.setHours(0, 0, 0, 0);
            const endOfDay = new Date(date as string);
            endOfDay.setHours(23, 59, 59, 999);

            query = query
                .or(`scheduled_at.gte.${startOfDay.toISOString()},deadline_at.gte.${startOfDay.toISOString()}`)
                .or(`scheduled_at.lte.${endOfDay.toISOString()},deadline_at.lte.${endOfDay.toISOString()}`);
        }

        const { data: executions, error } = await query;

        if (error) {
            console.error('[Get Executions Error]', error);
            return res.status(500).json({ error: 'Failed to fetch executions' });
        }

        res.json({ executions });
    } catch (error) {
        console.error('[Get Executions Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/executions - Create execution
router.post('/', requireAuth, validate(createExecutionSchema), async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { data: execution, error } = await supabase
            .from('executions')
            .insert(req.body)
            .select()
            .single();

        if (error) {
            console.error('[Create Execution Error]', error);
            return res.status(500).json({ error: 'Failed to create execution' });
        }

        res.status(201).json({ execution });
    } catch (error) {
        console.error('[Create Execution Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/executions/:id - Update execution
router.patch('/:id', requireAuth, validate(updateExecutionSchema), async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        const { data: execution, error } = await supabase
            .from('executions')
            .update(req.body)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('[Update Execution Error]', error);
            return res.status(404).json({ error: 'Execution not found or access denied' });
        }

        res.json({ execution });
    } catch (error) {
        console.error('[Update Execution Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/executions/:id/complete - Mark as completed and log
router.post('/:id/complete', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;
        const { notes } = req.body;

        // Update execution status
        const { data: execution, error: updateError } = await supabase
            .from('executions')
            .update({ status: 'completed' })
            .eq('id', id)
            .select()
            .single();

        if (updateError || !execution) {
            return res.status(404).json({ error: 'Execution not found or access denied' });
        }

        // Create log entry
        const { error: logError } = await supabase
            .from('execution_logs')
            .insert({
                execution_id: id,
                status: 'completed',
                notes: notes || null,
            });

        if (logError) {
            console.error('[Log Error]', logError);
        }

        res.json({ execution });
    } catch (error) {
        console.error('[Complete Execution Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE /api/executions/:id - Delete execution
router.delete('/:id', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        const { error } = await supabase
            .from('executions')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('[Delete Execution Error]', error);
            return res.status(404).json({ error: 'Execution not found or access denied' });
        }

        res.status(204).send();
    } catch (error) {
        console.error('[Delete Execution Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;
