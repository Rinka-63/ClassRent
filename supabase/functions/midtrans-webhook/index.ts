import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type MidtransWebhookPayload = {
  order_id?: string;
  transaction_id?: string;
  transaction_status?: string;
  fraud_status?: string;
  status_code?: string;
  gross_amount?: string;
  signature_key?: string;
  payment_type?: string;
  payment_method?: string;
  settlement_time?: string;
  transaction_time?: string;
  expiry_time?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const midtransServerKey = requiredEnv("MIDTRANS_SERVER_KEY");
    const payload = await req.json() as MidtransWebhookPayload;

    const orderId = payload.order_id;
    const statusCode = payload.status_code;
    const grossAmount = payload.gross_amount;
    const signatureKey = payload.signature_key;

    if (!orderId || !statusCode || !grossAmount || !signatureKey) {
      return jsonResponse({ error: "Invalid Midtrans webhook payload" }, 400);
    }

    const expectedSignature = await sha512(
      `${orderId}${statusCode}${grossAmount}${midtransServerKey}`,
    );
    if (signatureKey !== expectedSignature) {
      return jsonResponse({ error: "Invalid Midtrans signature" }, 401);
    }

    const transactionStatus = normalizeStatus(payload.transaction_status);
    const paidAt = paidTimestamp(payload);
    const expiredAt = payload.expiry_time ? toIsoString(payload.expiry_time) : null;

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const paymentUpdate = {
      transaction_id: payload.transaction_id ?? null,
      midtrans_transaction_id: payload.transaction_id ?? null,
      transaction_status: transactionStatus,
      status: legacyStatus(transactionStatus),
      payment_type: payload.payment_type ?? null,
      payment_method: payload.payment_method ?? payload.payment_type ?? null,
      midtrans_response: payload,
      webhook_payload: payload,
      paid_at: paidAt,
      expired_at: expiredAt,
    };

    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .update(removeNullish(paymentUpdate))
      .eq("order_id", orderId)
      .select("id,booking_id,transaction_status")
      .single();

    if (paymentError || !payment) {
      return jsonResponse({ error: "Payment not found" }, 404);
    }

    if (transactionStatus === "settlement" || transactionStatus === "capture") {
      const { error: bookingError } = await supabase
        .from("bookings")
        .update({ status: "confirmed" })
        .eq("id", payment.booking_id);

      if (bookingError) {
        throw bookingError;
      }
    }

    return jsonResponse({ received: true, payment_id: payment.id });
  } catch (error) {
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});

function normalizeStatus(status: string | undefined) {
  const allowedStatuses = [
    "pending",
    "capture",
    "settlement",
    "deny",
    "cancel",
    "expire",
    "failure",
    "refund",
  ];

  if (status && allowedStatuses.includes(status)) {
    return status;
  }

  return "failure";
}

function legacyStatus(status: string) {
  return status === "failure" ? "deny" : status;
}

function paidTimestamp(payload: MidtransWebhookPayload) {
  if (payload.transaction_status !== "settlement" && payload.transaction_status !== "capture") {
    return null;
  }

  return toIsoString(payload.settlement_time ?? payload.transaction_time ?? new Date().toISOString());
}

function toIsoString(value: string) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
}

async function sha512(value: string) {
  const data = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-512", data);
  return [...new Uint8Array(hash)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function removeNullish(record: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(record).filter(([, value]) => value !== null && value !== undefined),
  );
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
