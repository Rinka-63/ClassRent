import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const payload = await req.json();
    const { order_id, transaction_status, gross_amount, transaction_id } = payload;

    // Validate payload
    if (!order_id || !transaction_status) {
      return new Response("Invalid payload", { status: 400 });
    }

    // Midtrans order_id is formatted as 'CLASSRENT-<booking_id>'
    const bookingId = order_id.replace('CLASSRENT-', '');

    // Map Midtrans status to our status
    let paymentStatus = 'pending';
    let bookingStatus = 'pending_payment';

    switch (transaction_status) {
      case 'capture':
      case 'settlement':
        paymentStatus = 'settlement';
        bookingStatus = 'confirmed';
        break;
      case 'deny':
      case 'cancel':
      case 'expire':
        paymentStatus = transaction_status;
        bookingStatus = 'cancelled';
        break;
      case 'refund':
        paymentStatus = 'refund';
        bookingStatus = 'refunded';
        break;
      case 'pending':
        paymentStatus = 'pending';
        bookingStatus = 'pending_payment';
        break;
      default:
        // Other statuses can be logged but might not change our state
        break;
    }

    // 1. Update Booking Status
    const { error: bookingError } = await supabase
      .from('bookings')
      .update({ status: bookingStatus })
      .eq('id', bookingId);

    if (bookingError) throw bookingError;

    // 2. Update Payment Status if payments table is used
    // Assuming there's a payments table based on schema
    const { error: paymentError } = await supabase
      .from('payments')
      .update({
        status: paymentStatus,
        midtrans_transaction_id: transaction_id,
        webhook_payload: payload,
        updated_at: new Date().toISOString()
      })
      .eq('booking_id', bookingId);
      
    // If we don't have a payment record yet (maybe it wasn't inserted on checkout), we should insert it or just ignore if the error is 0 rows updated
    // But since audit logs depend on it, we just update it. The database trigger will automatically write to payment_logs.
    
    // We can also insert directly to payment_logs for manual audit
    await supabase.from('payment_logs').insert({
      booking_id: bookingId,
      event_type: 'midtrans_webhook',
      to_status: paymentStatus,
      midtrans_order_id: order_id,
      gross_amount: parseInt(gross_amount) || null,
      raw_payload: payload,
    });

    return new Response(JSON.stringify({ message: "Webhook processed successfully" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
