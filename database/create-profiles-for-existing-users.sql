-- Create profiles table entries for existing users who don't have one
-- This ensures admin filtering works correctly
-- Run this in Supabase SQL Editor

-- First, check how many users need profiles entries
SELECT 
    COUNT(*) as users_without_profiles
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Create profiles entries for users who don't have one
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    created_at,
    updated_at
)
SELECT 
    u.id,
    u.email,
    COALESCE(
        u.raw_user_meta_data->>'full_name',
        u.raw_user_meta_data->>'name',
        u.raw_user_meta_data->>'fighterName',
        split_part(u.email, '@', 1)
    ) as full_name,
    COALESCE(
        (u.raw_app_meta_data->>'role')::TEXT,
        (u.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) as role,
    u.created_at,
    NOW() as updated_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Verify the results
SELECT 
    COUNT(*) as total_users,
    COUNT(p.id) as users_with_profiles,
    COUNT(*) - COUNT(p.id) as users_without_profiles
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id;

-- Show created profiles
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.created_at
FROM public.profiles p
ORDER BY p.created_at DESC
LIMIT 10;


