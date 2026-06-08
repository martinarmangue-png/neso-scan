

import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function safeSelect(query, label) {
  const { data, error } = await query;

  if (error) {
    console.warn(`Optional admin dataset unavailable: ${label}`, error);
    return [];
  }

  return data || [];
}

async function withSignedDocumentUrls(documents) {
  return Promise.all((documents || []).map(async (document) => {
    if (!document.storage_bucket || !document.storage_path) {
      return {
        ...document,
        signed_url: null
      };
    }

    const { data, error } = await supabase.storage
      .from(document.storage_bucket)
      .createSignedUrl(document.storage_path, 60 * 15);

    return {
      ...document,
      signed_url: error ? null : data?.signedUrl || null
    };
  }));
}

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

    if (scansError) {
      return res.status(500).json({
        error: 'Database error',
        scansError
      });
    }

    const scanEvents = await safeSelect(
      supabase
        .from('scan_events')
        .select('*')
        .order('created_at', { ascending: false }),
      'scan_events'
    );

    const patientProfiles = await safeSelect(
      supabase
        .from('patient_profiles')
        .select('*')
        .order('updated_at', { ascending: false }),
      'patient_profiles'
    );

    const patientDocuments = await withSignedDocumentUrls(await safeSelect(
      supabase
        .from('patient_documents')
        .select('*')
        .order('created_at', { ascending: false }),
      'patient_documents'
    ));

    return res.status(200).json({
      scans,
      scanEvents,
      patientProfiles,
      patientDocuments
    });
  }

  return res.status(405).json({
    error: 'Method not allowed'
  });
}
