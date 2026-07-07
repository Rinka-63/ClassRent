import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type QueueRow = {
  id: string;
  notification_id: string;
  receiver_id: string;
  notifications: {
    title: string;
    body: string;
    type: string;
    reference_id: string | null;
  } | null;
  receiver: {
    fcm_token: string | null;
  } | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

  if (!serviceAccountJson) {
    return json({ error: "FIREBASE_SERVICE_ACCOUNT_JSON is not configured" }, 500);
  }

  const serviceAccount = JSON.parse(serviceAccountJson);
  const projectId = serviceAccount.project_id as string;
  const accessToken = await getFirebaseAccessToken(serviceAccount);

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await supabase
    .from("notification_push_queue")
    .select("id, notification_id, receiver_id, notifications(title, body, type, reference_id), receiver:users!notification_push_queue_receiver_id_fkey(fcm_token)")
    .eq("status", "pending")
    .order("created_at", { ascending: true })
    .limit(50);

  if (error) return json({ error: error.message }, 500);

  let sent = 0;
  let failed = 0;

  for (const row of (data ?? []) as QueueRow[]) {
    const token = row.receiver?.fcm_token;
    const notification = row.notifications;
    if (!token || !notification) {
      await markFailed(supabase, row.id, "Missing FCM token or notification");
      failed++;
      continue;
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: {
              notification_id: row.notification_id,
              type: notification.type,
              reference_id: notification.reference_id ?? "",
            },
            android: {
              priority: "HIGH",
              notification: {
                channel_id: "classrent_notifications",
              },
            },
          },
        }),
      },
    );

    if (response.ok) {
      await supabase
        .from("notification_push_queue")
        .update({ status: "sent", sent_at: new Date().toISOString() })
        .eq("id", row.id);
      sent++;
    } else {
      await markFailed(supabase, row.id, await response.text());
      failed++;
    }
  }

  return json({ sent, failed });
});

async function markFailed(
  supabase: ReturnType<typeof createClient>,
  id: string,
  message: string,
) {
  await supabase
    .from("notification_push_queue")
    .update({
      status: "failed",
      attempts: 1,
      last_error: message.slice(0, 500),
    })
    .eq("id", id);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function getFirebaseAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsignedJwt = `${base64Url(header)}.${base64Url(claim)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedJwt),
  );
  const jwt = `${unsignedJwt}.${arrayBufferToBase64Url(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!response.ok) {
    throw new Error(`Firebase OAuth failed: ${await response.text()}`);
  }
  const body = await response.json() as { access_token: string };
  return body.access_token;
}

function base64Url(value: unknown): string {
  return btoa(JSON.stringify(value))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll("\\n", "")
    .replaceAll("\n", "")
    .trim();
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}
