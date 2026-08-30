// supabase/functions/gemini-chat/index.ts
// VULN-08 Fix: Proxy seguro para Gemini AI - la API key nunca llega al APK
// Deploy: supabase functions deploy gemini-chat

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Rate limiting simple en memoria (por instancia)
const requestCounts = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 20;   // max 20 requests
const WINDOW_MS = 60000; // por minuto

function isRateLimited(userId: string): boolean {
  const now = Date.now();
  const userLimit = requestCounts.get(userId);

  if (!userLimit || now > userLimit.resetAt) {
    requestCounts.set(userId, { count: 1, resetAt: now + WINDOW_MS });
    return false;
  }

  if (userLimit.count >= RATE_LIMIT) return true;
  userLimit.count++;
  return false;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Requiere autenticacion Supabase
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Extraer user ID del JWT para rate limiting
    const token = authHeader.replace("Bearer ", "");
    let userId = "anonymous";
    try {
      const payload = JSON.parse(atob(token.split(".")[1]));
      userId = payload.sub ?? "anonymous";
    } catch (_) {}

    if (isRateLimited(userId)) {
      return new Response(JSON.stringify({ error: "Limite de peticiones alcanzado. Intenta en 1 minuto." }), {
        status: 429,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { message } = await req.json();
    if (!message || typeof message !== "string" || message.length > 2000) {
      return new Response(JSON.stringify({ error: "Mensaje invalido o demasiado largo" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(JSON.stringify({ error: "Servicio de IA no configurado" }), {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const models = ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-flash-8b"];
    
    for (const model of models) {
      try {
        const res = await fetch(
          "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + apiKey,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [{ parts: [{ text: message }] }],
              systemInstruction: {
                parts: [{
                  text: "Eres Master Mechanic, el asistente tecnico de My Auto Guide. Solo respondes sobre mecanica automotriz, mantenimiento de vehiculos y el uso de la aplicacion. Si te preguntan sobre otros temas, explica amablemente tu especialidad."
                }]
              }
            }),
          }
        );

        if (res.ok) {
          const data = await res.json();
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "Sin respuesta de la IA.";
          return new Response(JSON.stringify({ text, model }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } catch (_) {
        continue;
      }
    }

    return new Response(JSON.stringify({ error: "No se pudo conectar con la IA. Intenta mas tarde." }), {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (_) {
    return new Response(JSON.stringify({ error: "Error interno" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});