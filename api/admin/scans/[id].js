import { createSupabaseAdmin, requireActivePractitioner } from '../../_lib/auth.js';

const supabase = createSupabaseAdmin();

const ALLOWED_STATUSES = new Set(['new', 'seen', 'callback', 'handled']);

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
