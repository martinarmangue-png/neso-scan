import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

export default async function handler(req, res) {
  const adminPassword = req.headers['x-admin-password'];

  if (adminPassword !== process.env.ADMIN_PASSWORD) {
    return res.status(401).json({
      error: 'Unauthorized'
    });
  }

  if (req.method !== 'DELETE') {
    return res.status(405).json({
      error: 'Method not allowed'
    });
  }

  const scanId = req.query.id;

  if (!scanId) {
    return res.status(400).json({
      error: 'Missing scan id'
    });
  }

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
