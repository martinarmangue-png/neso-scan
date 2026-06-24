import { createSupabaseAdmin } from './_lib/auth.js';
import { Resend } from 'resend';

const ALLOWED_FIELDS = new Set([
  'scan_type', 'scan_type_label', 'prenom', 'zones',
  'douleur_depuis', 'type_douleur', 'score_douleur',
  'gene', 'evolution', 'objectif', 'duration_ms',
  'consent', 'source', 'patient_id', 'patient_email', 'patient_full_name'
]);

function sanitizePayload(body) {
  const payload = {};
  for (const [key, value] of Object.entries(body || {})) {
    if (ALLOWED_FIELDS.has(key)) payload[key] = value;
  }
  return payload;
}

function list(value) {
  return [value].flat().filter(Boolean).join(', ') || '—';
}

function formatEmail(scan) {
  const zone = scan.scan_type_label || scan.scan_type || '—';
  const prenom = scan.prenom || 'Patient anonyme';
  const score = scan.score_douleur != null ? `${scan.score_douleur} / 10` : '—';
  const depuis = scan.douleur_depuis || '—';
  const gene = list(scan.gene);
  const evolution = list(scan.evolution);
  const objectif = list(scan.objectif);
  const date = new Date().toLocaleDateString('fr-FR', {
    weekday: 'long', day: 'numeric', month: 'long',
    hour: '2-digit', minute: '2-digit'
  });

  const row = (label, value) => `
    <tr>
      <td style="padding:9px 0;border-bottom:0.5px solid #EAE7E0;font-size:11px;color:#888780;text-transform:uppercase;letter-spacing:0.1em;width:38%;vertical-align:top;">${label}</td>
      <td style="padding:9px 0;border-bottom:0.5px solid #EAE7E0;font-size:14px;color:#1C1C1A;">${value}</td>
    </tr>`;

  return {
    subject: `Nouveau Physio Scan — ${prenom} · ${zone}`,
    html: `
<div style="font-family:system-ui,-apple-system,sans-serif;max-width:520px;margin:0 auto;color:#1C1C1A;">
  <div style="background:#0C447C;padding:18px 24px;border-radius:14px 14px 0 0;">
    <p style="color:#E6F1FB;font-size:15px;font-weight:600;margin:0;letter-spacing:0.02em;">NESO Santé · Physio Scan</p>
  </div>
  <div style="background:#F7F5F0;padding:24px;border-radius:0 0 14px 14px;border:0.5px solid #DDD9D0;">
    <p style="font-size:19px;font-weight:600;margin:0 0 4px;">Nouveau scan reçu</p>
    <p style="font-size:12px;color:#B4B2A9;margin:0 0 22px;">${date}</p>
    <table style="width:100%;border-collapse:collapse;">
      ${row('Patient', `<strong>${prenom}</strong>`)}
      ${row('Zone', zone)}
      ${row('Douleur', score)}
      ${row('Depuis', depuis)}
      ${row('Gêne principale', gene)}
      ${row('Soulagement', evolution)}
      <tr>
        <td style="padding:9px 0;font-size:11px;color:#888780;text-transform:uppercase;letter-spacing:0.1em;width:38%;vertical-align:top;">Objectifs</td>
        <td style="padding:9px 0;font-size:14px;color:#1C1C1A;">${objectif}</td>
      </tr>
    </table>
    <div style="margin-top:24px;">
      <a href="https://www.nesosante.com/dashboard-v2.html"
         style="display:inline-block;background:linear-gradient(135deg,#185FA5,#0A5C48);color:#E1F5EE;text-decoration:none;padding:12px 20px;border-radius:10px;font-size:13px;font-weight:500;">
        Voir dans le dashboard →
      </a>
    </div>
  </div>
</div>`
  };
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
  const payload = sanitizePayload(body);

  if (!payload.consent) {
    return res.status(400).json({ error: 'Consent required' });
  }

  const supabase = createSupabaseAdmin();

  const { data: scan, error } = await supabase
    .from('scans')
    .insert(payload)
    .select('*')
    .single();

  if (error) {
    console.error('Scan insert error', error);
    return res.status(500).json({ error: 'Database error', details: error });
  }

  // Notification email (non-bloquante — l'insert est déjà confirmé)
  const practitionerEmail = process.env.PRACTITIONER_EMAIL;
  const resendKey = process.env.RESEND_API_KEY;

  if (practitionerEmail && resendKey) {
    const resend = new Resend(resendKey);
    const { subject, html } = formatEmail(scan);
    resend.emails.send({
      from: 'NESO Santé <notifications@nesosante.com>',
      to: practitionerEmail,
      subject,
      html
    }).catch(err => console.warn('Email notification failed', err.message));
  }

  return res.status(200).json({ ok: true, id: scan.id });
}
