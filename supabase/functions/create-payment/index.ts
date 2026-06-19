import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type BookingRow = {
  id: string;
  user_id: string;
  final_price: number;
  status: string;
};

type PaymentRow = {
  id: string;
  order_id: string | null;
  snap_token: string | null;
  snap_redirect_url: string | null;
  transaction_status: string;
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
    const isProduction = Deno.env.get("MIDTRANS_IS_PRODUCTION") === "true";
    const snapBaseUrl = isProduction
      ? "https://app.midtrans.com/snap/v1/transactions"
      : "https://app.sandbox.midtrans.com/snap/v1/transactions";

    const { booking_id } = await req.json();
    console.log("[create-payment] request", { booking_id });
    if (!booking_id || typeof booking_id !== "string") {
      return jsonResponse({ error: "booking_id is required" }, 400);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id,user_id,final_price,status")
      .eq("id", booking_id)
      .single<BookingRow>();

    if (bookingError || !booking) {
      console.error("[create-payment] booking not found", bookingError);
      return jsonResponse({ error: "Booking not found" }, 404);
    }

    const { data: existingPayments, error: existingError } = await supabase
      .from("payments")
      .select("id,order_id,snap_token,snap_redirect_url,transaction_status")
      .eq("booking_id", booking.id)
      .eq("transaction_status", "pending")
      .order("created_at", { ascending: false })
      .limit(1)
      .returns<PaymentRow[]>();

    if (existingError) {
      console.error("[create-payment] existing payment query failed", existingError);
      throw existingError;
    }

    const existingPayment = existingPayments?.[0];
    if (existingPayment?.snap_token && existingPayment.snap_redirect_url) {
      console.log("[create-payment] reused existing payment", {
        payment_id: existingPayment.id,
        order_id: existingPayment.order_id,
      });
      return jsonResponse({ payment: existingPayment, reused: true });
    }

    const orderId = existingPayment?.order_id ?? buildOrderId(booking.id);
    const grossAmount = Number(booking.final_price);
    const snapPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: grossAmount,
      },
      customer_details: {
        user_id: booking.user_id,
      },
      item_details: [
        {
          id: booking.id,
          price: grossAmount,
          quantity: 1,
          name: "ClassRent booking payment",
        },
      ],
    };

    const snapResponse = await fetch(snapBaseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Basic ${btoa(`${midtransServerKey}:`)}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify(snapPayload),
    });

    const snapJson = await snapResponse.json();
    console.log("[create-payment] snap response", {
      ok: snapResponse.ok,
      status: snapResponse.status,
      order_id: orderId,
    });
    if (!snapResponse.ok) {
      console.error("[create-payment] snap create failed", snapJson);
      return jsonResponse(
        { error: "Failed to create Midtrans Snap transaction", detail: snapJson },
        snapResponse.status,
      );
    }

    const paymentPayload = {
      booking_id: booking.id,
      user_id: booking.user_id,
      order_id: orderId,
      midtrans_order_id: orderId,
      gross_amount: grossAmount,
      amount: grossAmount,
      transaction_status: "pending",
      status: "pending",
      snap_token: snapJson.token,
      snap_redirect_url: snapJson.redirect_url,
      midtrans_response: snapJson,
    };

    const paymentQuery = existingPayment
      ? supabase
        .from("payments")
        .update(paymentPayload)
        .eq("id", existingPayment.id)
        .select()
        .single()
      : supabase
        .from("payments")
        .insert(paymentPayload)
        .select()
        .single();

    const { data: payment, error: paymentError } = await paymentQuery;
    if (paymentError) {
      console.error("[create-payment] payment upsert failed", paymentError);
      throw paymentError;
    }

    console.log("[create-payment] payment saved", {
      payment_id: payment.id,
      order_id: payment.order_id,
    });
    return jsonResponse({ payment, reused: false });
  } catch (error) {
    console.error("[create-payment] exception", error);
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});

function buildOrderId(bookingId: string) {
  const cleanBookingId = bookingId.replaceAll("-", "").slice(0, 12);
  return `CR-${cleanBookingId}-${Date.now()}`;
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
