import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type CreateStaffBody = {
  email?: string;
  password?: string;
  full_name?: string;
  agency_id?: string;
};

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: 'Missing Supabase environment variables' }, 500);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Missing authorization header' }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: callerData, error: callerError } = await userClient.auth.getUser();
  if (callerError || !callerData.user) {
    return json({ error: 'Invalid session' }, 401);
  }

  const body = (await req.json()) as CreateStaffBody;
  const email = body.email?.trim();
  const password = body.password;
  const fullName = body.full_name?.trim();
  const agencyId = body.agency_id;

  if (!email || !password || password.length < 6 || !fullName || !agencyId) {
    return json({ error: 'Invalid staff payload' }, 400);
  }

  const { data: agency, error: agencyError } = await userClient
    .from('agencies')
    .select('id,admin_id,approval_status,is_active')
    .eq('id', agencyId)
    .single();

  if (
    agencyError ||
    !agency ||
    agency.admin_id !== callerData.user.id ||
    agency.approval_status !== 'approved' ||
    agency.is_active !== true
  ) {
    return json({ error: 'You cannot create staff for this agency' }, 403);
  }

  const { data: created, error: createError } =
    await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        registration_type: 'staff_created_by_admin',
      },
      app_metadata: {
        role: 'staff',
        agency_id: agencyId,
        agency_status: 'approved',
        agency_is_active: true,
      },
    });

  if (createError || !created.user) {
    return json({ error: createError?.message ?? 'Could not create staff' }, 400);
  }

  const staffId = created.user.id;

  const { error: profileError } = await adminClient.from('users').upsert({
    id: staffId,
    email,
    full_name: fullName,
    role: 'staff',
  });

  if (profileError) return json({ error: profileError.message }, 500);

  const { error: assignmentError } = await adminClient
    .from('agency_staff')
    .upsert({
      staff_id: staffId,
      agency_id: agencyId,
      assigned_by: callerData.user.id,
    });

  if (assignmentError) return json({ error: assignmentError.message }, 500);

  return json({ staff_id: staffId }, 200);
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {'Content-Type': 'application/json'},
  });
}
