-- Fix function overloading by dropping old signatures
drop function if exists public.register_agency_admin_profile(text, text, text, text);
