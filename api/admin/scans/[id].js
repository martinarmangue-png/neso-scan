import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const ALLOWED_STATUSES = new Set(['new', 'seen', 'callback', 'handled']);

function readBearerToken(req) {
  const authorization = req.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) return '';
  return authorization.slice('Bearer '.length).trim();
}

async function requireActivePractitioner(req, res) {
  const token = readBearerToken(req);

  if (!token) {
    res.status(401).json({
      error: 'Unauthorized'
    });
    return null;
  }

  const { data: userResult, error: userError } = await supabase.auth.getUser(token);

  if (userError || !userResult?.user) {
    res.status(401).json({
      error: 'Unauthorized'
    });
    return null;
  }

  const { data: practitioner, error: practitionerError } = await supabase
    .from('practitioner_profiles')
    .select('id, email, full_name, is_active')
    .eq('id', userResult.user.id)
    .eq('is_active', true)
    .maybeSingle();

  if (practitionerError) {
    console.error('Practitioner auth lookup failed', practitionerError);
    res.status(500).json({
      error: 'Practitioner auth unavailable'
    });
    return null;
  }

  if (!practitioner) {
    res.status(403).json({
      error: 'Forbidden'
    });
    return null;
  }

  return practitioner;
}

function readBody(req) {
  if (!req.body) return {};
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }
  return req.body;
}

export default async function handler(req, res) {
  const practitioner = await requireActivePractitioner(req, res);
  if (!practitioner) return;

  const scanId = req.query.id;

  if (!scanId) {
    return res.status(400).json({
      error: 'Missing scan id'
    });
  }

  if (req.method === 'PATCH') {
    const body = readBody(req);
    const practitionerStatus = body.practitioner_status;

    if (!ALLOWED_STATUSES.has(practitionerStatus)) {
      return res.status(400).json({
        error: 'Invalid practitioner status'
      });
    }

    const { data, error } = await supabase
      .from('scans')
      .update({
        practitioner_status: practitionerStatus,
        practitioner_status_updated_at: new Date().toISOString()
      })
      .eq('id', scanId)
      .select('*')
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        details: error
      });
    }

    return res.status(200).json({
      scan: data
    });
  }

  if (req.method === 'DELETE') {
    const { error } = await supabase
      .from('scans')
      .delete()
      .eq('id', scanId);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        details: error
      });
    }

    return res.status(200).json({
      ok: true
    });
  }

  return res.status(405).json({
    error: 'Method not allowed'
  });
}
