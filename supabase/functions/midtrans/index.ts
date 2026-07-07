import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  
  // Important: Server key is loaded securely from the Edge environment, not from client
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY') ?? '';
  const isProduction = Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true';

  const baseUrl = isProduction 
    ? 'https://app.midtrans.com/snap/v1' 
    : 'https://app.sandbox.midtrans.com/snap/v1';

  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // ROUTE 1: GET SNAP TOKEN
    if (path === 'snap' && req.method === 'POST') {
      const payload = await req.json();

      const authString = btoa(`${serverKey}:`);
      
      const response = await fetch(`${baseUrl}/transactions`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': `Basic ${authString}`
        },
        body: JSON.stringify(payload)
      });

      const responseData = await response.json();
      
      if (!response.ok) {
        throw new Error(`Midtrans API Error: ${JSON.stringify(responseData)}`);
      }

      return new Response(JSON.stringify(responseData), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // ROUTE 2: HANDLE WEBHOOK NOTIFICATION
    if (path === 'webhook' && req.method === 'POST') {
      const notification = await req.json();
      
      const transactionStatus = notification.transaction_status;
      const orderId = notification.order_id;
      const fraudStatus = notification.fraud_status;

      // Ensure orderId structure: uuid32-timestamp
      // We stored uuid32, so we slice the first 32 chars and reconstruct the booking ID (8-4-4-4-12 format)
      if (orderId && orderId.length >= 32) {
        const uuidStr = orderId.substring(0, 32);
        const bookingId = `${uuidStr.substring(0, 8)}-${uuidStr.substring(8, 12)}-${uuidStr.substring(12, 16)}-${uuidStr.substring(16, 20)}-${uuidStr.substring(20, 32)}`;

        let finalStatus = 'pending_payment';
        let paymentStatus = 'pending';

        if (transactionStatus == 'capture') {
          if (fraudStatus == 'challenge') {
            finalStatus = 'pending_payment';
            paymentStatus = 'challenge';
          } else if (fraudStatus == 'accept') {
            finalStatus = 'confirmed';
            paymentStatus = 'success';
          }
        } else if (transactionStatus == 'settlement') {
          finalStatus = 'confirmed';
          paymentStatus = 'success';
        } else if (transactionStatus == 'cancel' || transactionStatus == 'deny' || transactionStatus == 'expire') {
          finalStatus = 'cancelled';
          paymentStatus = 'failed';
        } else if (transactionStatus == 'pending') {
          finalStatus = 'pending_payment';
          paymentStatus = 'pending';
        }

        // Update Payment table
        const { error: paymentError } = await supabase
          .from('payments')
          .update({
            status: paymentStatus,
            payment_type: notification.payment_type,
            updated_at: new Date().toISOString()
          })
          .eq('booking_id', bookingId);
          
        if (paymentError) {
          console.error('Error updating payment', paymentError);
        }

        // Update Booking table
        const { error: bookingError } = await supabase
          .from('bookings')
          .update({
            status: finalStatus,
            updated_at: new Date().toISOString()
          })
          .eq('id', bookingId);

        if (bookingError) {
          console.error('Error updating booking', bookingError);
        }

        return new Response(JSON.stringify({ status: 'success', message: 'Webhook processed' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }
      
      return new Response(JSON.stringify({ status: 'error', message: 'Invalid order_id format' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // DEFAULT
    return new Response(JSON.stringify({ error: 'Route not found' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 404,
    });

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
