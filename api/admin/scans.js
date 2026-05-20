

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

  if (req.method === 'GET') {
    const { data: scans, error: scansError } = await supabase
      .from('scans')
      .select('*')
      .order('created_at', { ascending: false });

    const { data: scanEvents, error: eventsError } = await supabase
      .from('scan_events')
      .select('*')
      .order('created_at', { ascending: false });

    if (scansError || eventsError) {
      return res.status(500).json({
        error: 'Database error',
        scansError,
        eventsError
      });
    }

    return res.status(200).json({
      scans,
      scanEvents
    });
  }

  return res.status(405).json({
    error: 'Method not allowed'
  });
}