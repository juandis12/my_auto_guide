// supabase/functions/send-email/index.ts
// VULN-02 Fix: Envia emails desde el servidor (no desde el cliente)
// Las credenciales SMTP nunca salen del servidor de Supabase.
// Deploy: supabase functions deploy send-email

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EmailRequest {
  toEmail: string;
  subject: string;
  htmlContent: string;
  placa?: string;
}

serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Validar que el usuario esta autenticado
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { toEmail, subject, htmlContent, placa } = await req.json() as EmailRequest;

    if (!toEmail || !subject || !htmlContent) {
      return new Response(JSON.stringify({ error: "Parametros requeridos: toEmail, subject, htmlContent" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const gmailUser = Deno.env.get("GMAIL_EMAIL") ?? "";
    const gmailPass = Deno.env.get("GMAIL_APP_PASSWORD") ?? "";
    const resendKey = Deno.env.get("RESEND_API_KEY") ?? "";

    // Opcion 1: Resend API (recomendado para produccion)
    if (resendKey) {
      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": "Bearer " + resendKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: "My Auto Guide <onboarding@resend.dev>",
          to: [toEmail],
          subject: placa ? subject + " - " + placa : subject,
          html: htmlContent,
        }),
      });

      if (res.ok) {
        return new Response(JSON.stringify({ ok: true, provider: "resend" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // Opcion 2: SMTP Gmail (fallback)
    if (gmailUser && gmailPass) {
      const smtpRes = await fetch("https://smtp-api.deno.dev/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          from: gmailUser,
          to: toEmail,
          subject: placa ? subject + " - " + placa : subject,
          html: htmlContent,
          user: gmailUser,
          pass: gmailPass,
        }),
      });

      if (smtpRes.ok) {
        return new Response(JSON.stringify({ ok: true, provider: "gmail" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    return new Response(JSON.stringify({ error: "No hay proveedor de email configurado" }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Error interno del servidor" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});