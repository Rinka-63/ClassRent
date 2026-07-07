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

    // Parse order_id. Current format: {uuid32}-{timestamp}
    // Note: old format was 'CLASSRENT-<booking_id>-<timestamp>'
    let bookingId = '';
    if (order_id.startsWith('CLASSRENT-')) {
      // Legacy format
      bookingId = order_id.replace('CLASSRENT-', '');
      const lastDashIndex = bookingId.lastIndexOf('-');
      if (lastDashIndex > -1) {
        const timestampPart = bookingId.substring(lastDashIndex + 1);
        if (/^\d+$/.test(timestampPart)) {
          bookingId = bookingId.substring(0, lastDashIndex);
        }
      }
    } else {
      // New format: {uuid32}-{timestamp}
      const parts = order_id.split('-');
      const uuid32 = parts[0];
      if (uuid32.length === 32) {
        bookingId = `${uuid32.slice(0,8)}-${uuid32.slice(8,12)}-${uuid32.slice(12,16)}-${uuid32.slice(16,20)}-${uuid32.slice(20)}`;
      } else {
        return new Response("Invalid order_id format", { status: 400 });
      }
    }

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

    // 1. Update Booking Status — never re-activate auto-cancelled bookings
    const { data: existingBooking, error: fetchBookingError } = await supabase
      .from('bookings')
      .select('status,user_id')
      .eq('id', bookingId)
      .maybeSingle();

    if (fetchBookingError) throw fetchBookingError;

    const currentStatus = (existingBooking?.status as string | undefined)?.toLowerCase();
    const isLatePaymentOnCancelled =
      (currentStatus === 'cancelled' || currentStatus === 'rejected') &&
      (transaction_status === 'capture' || transaction_status === 'settlement');

    if (isLatePaymentOnCancelled) {
      // Log webhook but do not confirm booking again
      await supabase.from('payment_logs').insert({
        booking_id: bookingId,
        event_type: 'midtrans_webhook_ignored',
        to_status: paymentStatus,
        midtrans_order_id: order_id,
        gross_amount: parseInt(gross_amount) || null,
        raw_payload: payload,
      });
      return new Response(
        JSON.stringify({ message: 'Payment ignored — booking already cancelled' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 },
      );
    }

    const { error: bookingError } = await supabase
      .from('bookings')
      .update({ status: bookingStatus })
      .eq('id', bookingId);

    if (bookingError) throw bookingError;

    if (bookingStatus === 'confirmed' && existingBooking?.user_id) {
      const { data: existingNotification } = await supabase
        .from('notifications')
        .select('id')
        .eq('receiver_id', existingBooking.user_id)
        .eq('type', 'payment_success')
        .eq('reference_id', bookingId)
        .maybeSingle();

      if (!existingNotification) {
        await supabase.from('notifications').insert({
          receiver_id: existingBooking.user_id,
          user_id: existingBooking.user_id,
          sender_id: null,
          title: 'Pembayaran berhasil',
          body: 'Pembayaran berhasil. Booking kamu sudah dikonfirmasi.',
          type: 'payment_success',
          reference_id: bookingId,
          data: { reference_id: bookingId },
        });
      }
    }

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
