// ============================================
// AI Routes - Gemini Integration
// ============================================
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { supabase } from '../index';
import { AI_CONFIG } from '@cordly/shared/constants';


const router = Router();

// Initialize Gemini
let genAI: GoogleGenerativeAI | null = null;
if (process.env.GEMINI_API_KEY) {
    genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
}

// Validation schema
const chatSchema = z.object({
    workspace_id: z.string().uuid(),
    message: z.string().min(1).max(2000),
});

// Simple in-memory rate limiter per user
const rateLimiter = new Map<string, number[]>();

const checkRateLimit = (userId: string): boolean => {
    const now = Date.now();
    const userRequests = rateLimiter.get(userId) || [];

    // Filter requests within the last minute
    const recentRequests = userRequests.filter(
        (timestamp) => now - timestamp < AI_CONFIG.RATE_LIMIT_WINDOW_MS
    );

    if (recentRequests.length >= AI_CONFIG.RATE_LIMIT_MAX_REQUESTS) {
        return false;
    }

    recentRequests.push(now);
    rateLimiter.set(userId, recentRequests);
    return true;
};

// POST /api/ai/chat - Chat with AI assistant
router.post('/chat', requireAuth, validate(chatSchema), async (req: AuthRequest, res) => {
    try {
        if (!genAI) {
            return res.status(503).json({ error: 'AI service not configured' });
        }

        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        // Rate limiting
        if (!checkRateLimit(req.userId!)) {
            return res.status(429).json({
                error: 'Rate limit exceeded. Please try again in a minute.'
            });
        }

        const { workspace_id, message } = req.body;

        // Fetch context from workspace (last 30 days of data)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const [executionsResult, peopleResult] = await Promise.all([
            supabase
                .from('executions')
                .select('title, type, status, scheduled_at, deadline_at')
                .eq('workspace_id', workspace_id)
                .gte('created_at', thirtyDaysAgo.toISOString())
                .limit(50),
            supabase
                .from('people')
                .select('name, company, event_met, date_met, tags')
                .eq('workspace_id', workspace_id)
                .limit(50),
        ]);

        // Build context
        const context = {
            executions: executionsResult.data || [],
            people: peopleResult.data || [],
        };

        // Create prompt
        const systemPrompt = `You are the CORDLY AI assistant. You help users recall context, analyze patterns, and suggest actions based on their personal data.

Your personality:
- Brutally honest and direct
- Analytical and pattern-focused
- No hand-holding or motivational fluff
- Focus on truth and actionable insights

User's context:
- Recent executions: ${JSON.stringify(context.executions, null, 2)}
- People met: ${JSON.stringify(context.people, null, 2)}

Answer the user's question based on this context. If the data doesn't exist, say so clearly.`;

        const model = genAI.getGenerativeModel({ model: AI_CONFIG.MODEL });

        const result = await model.generateContent([
            systemPrompt,
            `User question: ${message}`,
        ]);

        const response = result.response.text();

        res.json({
            response,
            context_used: {
                executions_count: context.executions.length,
                people_count: context.people.length,
            }
        });
    } catch (error: any) {
        console.error('[AI Chat Error]', error);

        if (error?.message?.includes('quota')) {
            return res.status(429).json({
                error: 'AI quota exceeded. Please try again later.'
            });
        }

        res.status(500).json({ error: 'Failed to generate response' });
    }
});

// POST /api/ai/summarize-day - Generate daily summary
router.post('/summarize-day', requireAuth, async (req: AuthRequest, res) => {
    try {
        if (!genAI) {
            return res.status(503).json({ error: 'AI service not configured' });
        }

        if (!supabase) {
            return res.status(500).json({ error: 'Database not configured' });
        }

        if (!checkRateLimit(req.userId!)) {
            return res.status(429).json({
                error: 'Rate limit exceeded. Please try again in a minute.'
            });
        }

        const { workspace_id, date } = req.body;
        const targetDate = date || new Date().toISOString().split('T')[0];

        // Fetch day's executions
        const { data: executions } = await supabase
            .from('executions')
            .select('*')
            .eq('workspace_id', workspace_id)
            .or(`scheduled_at.gte.${targetDate}T00:00:00,deadline_at.gte.${targetDate}T00:00:00`)
            .or(`scheduled_at.lte.${targetDate}T23:59:59,deadline_at.lte.${targetDate}T23:59:59`);

        const model = genAI.getGenerativeModel({ model: AI_CONFIG.MODEL });

        const prompt = `Summarize this day's executions in 2-3 sentences. Focus on: completion rate, patterns, and key accomplishments or missed items.

Executions: ${JSON.stringify(executions, null, 2)}`;

        const result = await model.generateContent(prompt);
        const summary = result.response.text();

        res.json({ summary, date: targetDate });
    } catch (error) {
        console.error('[AI Summarize Error]', error);
        res.status(500).json({ error: 'Failed to generate summary' });
    }
});

export default router;
