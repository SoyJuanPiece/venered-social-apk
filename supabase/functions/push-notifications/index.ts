import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-client@2"

serve(async (req) => {
  try {
    const { record } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. Obtener el token del receptor
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("fcm_token")
      .eq("id", record.receiver_id)
      .single();

    if (!profile?.fcm_token) return new Response("No token", { status: 200 });

    // 2. Obtener el nombre del que envía
    const { data: sender } = await supabaseAdmin
      .from("profiles")
      .select("username")
      .eq("id", record.sender_id)
      .single();

    // 3. Enviar a Firebase usando la API Legacy (más fácil de configurar sin CLI)
    // NOTA: Debes poner tu SERVER KEY de Firebase en los secretos de Supabase
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${Deno.env.get("FIREBASE_SERVER_KEY")}`,
      },
      body: JSON.stringify({
        to: profile.fcm_token,
        notification: {
          title: record.type === 'message' ? `Mensaje de ${sender?.username}` : 'Venered Social',
          body: record.content,
          sound: "default",
          icon: "stock_ticker_update"
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: record.type,
        },
        priority: "high"
      }),
    });

    return new Response(await response.text(), { status: 200 });
  } catch (e) {
    return new Response(e.message, { status: 500 });
  }
});
