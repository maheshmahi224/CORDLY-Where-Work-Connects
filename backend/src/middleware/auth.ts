// ============================================
// Auth Middleware - JWT Verification
// ============================================
import { Request, Response, NextFunction } from 'express';
import { supabase } from '../index';

export interface AuthRequest extends Request {
    userId?: string;
}

export const requireAuth = async (
    req: AuthRequest,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ error: 'Unauthorized: No token provided' });
            return;
        }

        const token = authHeader.substring(7);

        if (!supabase) {
            res.status(500).json({ error: 'Database not configured' });
            return;
        }

        // Verify JWT token
        const { data, error } = await supabase.auth.getUser(token);

        if (error || !data.user) {
            res.status(401).json({ error: 'Unauthorized: Invalid token' });
            return;
        }

        // Attach user ID to request
        req.userId = data.user.id;
        next();
    } catch (error) {
        console.error('[Auth Middleware Error]', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
