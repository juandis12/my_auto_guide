// supabase/functions/send-email/index.ts
// VULN-02 & Alerts Fix: Envia correos responsivos Premium desde el servidor.
// Soporta: Reportes SIMIT y Alertas de Mantenimiento (Preventivo 40%-50% / Critico <10%)
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
  htmlContent?: string;
  placa?: string;
  
  // Parametros para alerta de mantenimiento
  userName?: string;
  maintenanceType?: string;
  remainingPct?: number;
  currentKms?: number;
  vehicleBrand?: string;
  vehicleNickname?: string;
  vehicleImagePath?: string;
  isPreventive?: boolean;
}

serve(async (req: Request) => {
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

    const body = await req.json() as EmailRequest;
    const { toEmail, subject, placa } = body;

    if (!toEmail || !subject) {
      return new Response(JSON.stringify({ error: "Parametros requeridos: toEmail, subject" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const gmailUser = Deno.env.get("GMAIL_EMAIL") ?? "";
    const gmailPass = Deno.env.get("GMAIL_APP_PASSWORD") ?? "";
    const resendKey = Deno.env.get("RESEND_API_KEY") ?? "";

    // ─── CONSTRUIR HTML PREMIUM SEGUN TIPO DE CORREO ─────────────────────────
    let finalHtml = '';

    if (body.maintenanceType) {
      // Es una alerta de mantenimiento
      finalHtml = buildMaintenanceHtml(body);
    } else {
      // Es el reporte del SIMIT tradicional (con diseño premium mejorado)
      finalHtml = body.htmlContent || '<h1>My Auto Guide</h1>';
    }

    // 1. Enviar usando Resend (gratis hasta 3000 correos/mes, bandeja de entrada directa)
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
            to: [toEmail.trim()],
            subject: placa ? `${subject} - ${placa}` : subject,
            html: finalHtml,
          }),
        });

        if (res.ok) {
          return new Response(JSON.stringify({ ok: true, provider: "resend" }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } catch (e) {
        console.error("Error enviando por Resend: ", e);
      }
    }

    // 2. Fallback a Gmail SMTP usando nodemailer
    if (gmailUser && gmailPass) {
      const cleanUser = gmailUser.trim();
      const cleanPass = gmailPass.replace(/\s+/g, "").trim();

      const transporter = nodemailer.createTransport({
        host: "smtp.gmail.com",
        port: 465,
        secure: true,
        auth: {
          user: cleanUser,
          pass: cleanPass,
        },
      });

      await transporter.sendMail({
        from: `"My Auto Guide" <${cleanUser}>`,
        to: toEmail.trim(),
        subject: placa ? `${subject} - ${placa}` : subject,
        html: finalHtml,
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

// ─── PLANTILLA DE CORREO DE ALERTA MECÁNICA PREMIUM ────────────────────────
function buildMaintenanceHtml(b: EmailRequest): string {
  const isPrev = b.isPreventive ?? false;
  
  // Colores temáticos dinámicos
  const mainColor = isPrev ? '#FF9500' : '#FF3B30'; // Naranja preventivo vs Rojo crítico
  const alertText = isPrev ? 'ATENCIÓN REQUERIDA' : 'ATENCIÓN INMEDIATA';
  const alertDesc = isPrev 
    ? 'Se ha detectado un servicio preventivo próximo a vencerse.' 
    : 'Se ha alcanzado un límite de desgaste crítico en los componentes del vehículo.';

  const pctStr = ((b.remainingPct ?? 0) * 100).toStringAsFixed(0);
  const nickname = b.vehicleNickname ?? 'Mi Vehículo';
  const brand = b.vehicleBrand ?? '';
  const kms = b.currentKms?.toString() ?? '0';

  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alerta de Mantenimiento - My Auto Guide</title>
    <style>
      body {
        margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        background-color: #0A0C10; color: #FFFFFF;
      }
      .container {
        max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0A0C10;
      }
      .card {
        background-color: #14171F; border-radius: 20px; border: 1.5px solid #1F2430; padding: 30px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      }
      .header {
        text-align: center; margin-bottom: 30px;
      }
      .logo {
        font-size: 24px; font-weight: 800; color: #00FF87; letter-spacing: 1px; margin-bottom: 10px;
      }
      .badge {
        display: inline-block; padding: 6px 12px; border-radius: 30px; font-size: 11px; font-weight: 900;
        letter-spacing: 0.8px; color: #000000; background-color: ${mainColor}; margin-bottom: 20px;
      }
      .title {
        font-size: 20px; font-weight: 800; margin: 0 0 10px 0; color: #FFFFFF; text-align: center;
      }
      .desc {
        font-size: 13px; color: #A0AEC0; text-align: center; line-height: 1.5; margin-bottom: 25px;
      }
      .info-grid {
        background-color: #0D0F14; border-radius: 14px; padding: 20px; margin-bottom: 25px; border: 1px solid #181C26;
      }
      .info-row {
        display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #1F2430;
      }
      .info-row:last-child {
        border-bottom: none;
      }
      .label {
        font-size: 12px; color: #718096; text-transform: uppercase; font-weight: 700;
      }
      .value {
        font-size: 13px; color: #FFFFFF; font-weight: 600;
      }
      .progress-container {
        margin: 25px 0;
      }
      .progress-bar {
        background-color: #1F2430; height: 12px; border-radius: 6px; overflow: hidden; margin-top: 8px;
      }
      .progress-fill {
        background-color: ${mainColor}; height: 100%; width: ${pctStr}%; border-radius: 6px;
      }
      .btn {
        display: block; width: 85%; margin: 30px auto 10px auto; padding: 15px; border-radius: 12px;
        background-color: #035880; color: #FFFFFF; text-align: center; font-weight: 700; font-size: 14px;
        text-decoration: none; box-shadow: 0 4px 15px rgba(3, 88, 128, 0.4);
      }
      .footer {
        font-size: 10px; color: #4A5568; text-align: center; margin-top: 30px; line-height: 1.4;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="card">
        <div class="header">
          <div class="logo">MY AUTO GUIDE</div>
          <div class="badge">${alertText}</div>
          <h2 class="title">Alerta de ${b.maintenanceType}</h2>
          <p class="desc">Hola ${b.userName || 'Conductor'},<br>${alertDesc}</p>
        </div>

        <div class="info-grid">
          <div class="info-row">
            <span class="label">Vehículo</span>
            <span class="value">${nickname} (${brand})</span>
          </div>
          <div class="info-row">
            <span class="label">Kilometraje Actual</span>
            <span class="value">${kms} km</span>
          </div>
          <div class="info-row">
            <span class="label">Servicio</span>
            <span class="value">${b.maintenanceType}</span>
          </div>
        </div>

        <div class="progress-container">
          <div style="display: flex; justify-content: space-between; font-size: 12px;">
            <span style="color: #718096;">Vida Útil Restante</span>
            <span style="font-weight: 700; color: ${mainColor};">${pctStr}%</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill"></div>
          </div>
        </div>

        <a href="myautoguide://home" class="btn">ABRIR MI AUTO GUIDE</a>

        <div class="footer">
          Este es un correo electrónico automático del sistema de telemetría de My Auto Guide.<br>
          © 2026 My Auto Guide. Todos los derechos reservados.
        </div>
      </div>
    </div>
  </body>
  </html>
  `;
}