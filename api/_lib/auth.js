import { createClient } from '@supabase/supabase-js';

export function createSupabaseAdmin() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );
}

export async function requireActivePractitioner(req, res) {
  const supabase = createSupabaseAdmin();

  const authorization = req.headers.authorization || '';
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : '';

  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return null;
  }

  const { data: userResult, error: userError } = await supabase.auth.getUser(token);
  if (userError || !userResult?.user) {
    res.status(401).json({ error: 'Unauthorized' });
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
    res.status(500).json({ error: 'Practitioner auth unavailable' });
    return null;
  }

  if (!practitioner) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }

  return practitioner;
}
