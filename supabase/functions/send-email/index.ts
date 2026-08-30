// supabase/functions/send-email/index.ts
// VULN-02 Fix: Envia correos usando nodemailer desde NPM (compatible con Deno nativo)
// Deploy: supabase.cmd functions deploy send-email --project-ref xstzerpnupubyfbhrrzu

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import nodemailer from "npm:nodemailer";

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

    // 1. Resend API
    if (resendKey) {
      try {
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
      } catch (e) {
        console.error("Error con Resend: ", e);
      }
    }

    // 2. SMTP Gmail usando nodemailer
    if (gmailUser && gmailPass) {
      const cleanUser = gmailUser.trim();
      const cleanPass = gmailPass.replace(/\s+/g, "").trim();

      const transporter = nodemailer.createTransport({
        host: "smtp.gmail.com",
        port: 465,
        secure: true, // true para 465 (SSL)
        auth: {
          user: cleanUser,
          pass: cleanPass,
        },
      });

      await transporter.sendMail({
        from: `"My Auto Guide" <${cleanUser}>`,
        to: toEmail.trim(),
        subject: placa ? `${subject} - ${placa}` : subject,
        html: htmlContent,
      });

      return new Response(JSON.stringify({ ok: true, provider: "nodemailer-gmail" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "No hay proveedor de email configurado" }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Error en send-email: ", err);
    return new Response(JSON.stringify({ error: err.message ?? "Error interno" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});