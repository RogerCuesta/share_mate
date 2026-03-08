import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const jsonResponse = (
  payload: Record<string, unknown>,
  status = 200,
): Response =>
  new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse(
      {
        success: false,
        code: "METHOD_NOT_ALLOWED",
        message: "Only POST requests are allowed.",
      },
      405,
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse(
      {
        success: false,
        code: "SERVER_CONFIG_MISSING",
        message: "Function environment is missing required Supabase variables.",
      },
      500,
    );
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse(
      {
        success: false,
        code: "UNAUTHORIZED",
        message: "Missing or invalid bearer token.",
      },
      401,
    );
  }

  const authedClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: authorization } },
  });

  const { data: authData, error: authError } = await authedClient.auth.getUser();
  const actorUser = authData.user;
  if (authError != null || actorUser == null) {
    return jsonResponse(
      {
        success: false,
        code: "UNAUTHORIZED",
        message: "Unable to resolve authenticated user.",
      },
      401,
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(actorUser.id);
  if (deleteError != null) {
    console.error("delete-account failed", {
      actorUserId: actorUser.id,
      reason: deleteError.message,
    });

    return jsonResponse(
      {
        success: false,
        code: "ACCOUNT_DELETE_FAILED",
        message: "Unable to delete account at this time.",
      },
      500,
    );
  }

  return jsonResponse({
    success: true,
    code: "ACCOUNT_DELETED",
    message: "Account deleted successfully.",
  });
});
