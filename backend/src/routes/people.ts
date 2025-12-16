// ============================================
// People Routes - Relationship Memory
// ============================================
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { supabase } from '../index';

const router = Router();

// Validation schemas
const createPersonSchema = z.object({
    workspace_id: z.string().uuid(),
    name: z.string().min(1).max(200),
    role: z.string().optional(),
    company: z.string().optional(),
    linkedin_url: z.string().url().optional(),
    event_met: z.string().optional(),
    date_met: z.string().optional(),
    location_met: z.string().optional(),
    tags: z.array(z.string()).optional(),
    notes: z.string().optional(),
    follow_up_status: z.enum(['none', 'pending', 'done']).optional(),
});

const updatePersonSchema = createPersonSchema.partial().omit({ workspace_id: true });

// GET /api/people?workspace_id=xxx&search=xxx&tag=xxx
router.get('/', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { workspace_id, search, tag, follow_up_status } = req.query;

        if (!workspace_id) {
            return res.status(400).json({ error: 'workspace_id is required' });
        }

        let query = supabase
            .from('people')
            .select('*')
            .eq('workspace_id', workspace_id as string)
            .order('created_at', { ascending: false });

        if (search) {
            query = query.or(
                `name.ilike.%${search}%,company.ilike.%${search}%,event_met.ilike.%${search}%,notes.ilike.%${search}%`
            );
        }

        if (tag) {
            query = query.contains('tags', [tag as string]);
        }

        if (follow_up_status) {
            query = query.eq('follow_up_status', follow_up_status as string);
        }

        const { data: people, error } = await query;

        if (error) {
            console.error('[Get People Error]', error);
            return res.status(500).json({ error: 'Failed to fetch people' });
        }

        res.json({ people });
    } catch (error) {
        console.error('[Get People Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/people - Create person
router.post('/', requireAuth, validate(createPersonSchema), async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { data: person, error } = await supabase
            .from('people')
            .insert(req.body)
            .select()
            .single();

        if (error) {
            console.error('[Create Person Error]', error);
            return res.status(500).json({ error: 'Failed to create person' });
        }

        res.status(201).json({ person });
    } catch (error) {
        console.error('[Create Person Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/people/:id - Get person by ID
router.get('/:id', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        const { data: person, error } = await supabase
            .from('people')
            .select('*')
            .eq('id', id)
            .single();

        if (error || !person) {
            return res.status(404).json({ error: 'Person not found or access denied' });
        }

        res.json({ person });
    } catch (error) {
        console.error('[Get Person Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/people/:id - Update person
router.patch('/:id', requireAuth, validate(updatePersonSchema), async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        const { data: person, error } = await supabase
            .from('people')
            .update(req.body)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            return res.status(404).json({ error: 'Person not found or access denied' });
        }

        res.json({ person });
    } catch (error) {
        console.error('[Update Person Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE /api/people/:id - Delete person
router.delete('/:id', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        const { id } = req.params;

        const { error } = await supabase
            .from('people')
            .delete()
            .eq('id', id);

        if (error) {
            return res.status(404).json({ error: 'Person not found or access denied' });
        }

        res.status(204).send();
    } catch (error) {
        console.error('[Delete Person Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;
