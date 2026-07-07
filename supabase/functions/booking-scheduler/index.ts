import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const [reminders, expired] = await Promise.all([
    supabase.rpc("process_booking_reminders"),
    supabase.rpc("expire_past_bookings"),
  ]);

  if (reminders.error || expired.error) {
    return json({
      reminder_error: reminders.error?.message,
      expired_error: expired.error?.message,
    }, 500);
  }

  return json({
    reminders_created: reminders.data ?? 0,
    bookings_expired: expired.data ?? 0,
  });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
