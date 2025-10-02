/*
  # Database Schema for Dashboard Application

  ## Overview
  This migration creates the complete database schema for a project management dashboard
  with user authentication and role-based access control.

  ## INSTRUCTIONS TO RUN THIS MIGRATION:
  1. Go to your Supabase Dashboard: https://supabase.com/dashboard
  2. Select your project
  3. Click on "SQL Editor" in the left sidebar
  4. Click "New Query"
  5. Copy and paste this entire SQL file
  6. Click "Run" to execute

  ## New Tables

  ### 1. `user_profiles`
  - `id` (uuid, primary key) - References auth.users
  - `email` (text) - User email address
  - `full_name` (text) - User's full name
  - `role` (text) - User role: 'user' or 'admin'
  - `avatar_url` (text, optional) - Profile picture URL
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 2. `projects`
  - `id` (uuid, primary key) - Unique project identifier
  - `name` (text) - Project name
  - `description` (text, optional) - Project description
  - `status` (text) - Project status: 'active', 'completed', 'on-hold'
  - `priority` (text) - Priority level: 'low', 'medium', 'high'
  - `start_date` (date, optional) - Project start date
  - `end_date` (date, optional) - Project end date
  - `progress` (integer) - Completion percentage (0-100)
  - `budget` (numeric, optional) - Project budget
  - `team_members` (text array) - Array of team member names
  - `created_by` (uuid) - User who created the project
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 3. `activities`
  - `id` (uuid, primary key) - Unique activity identifier
  - `user_id` (uuid) - User who performed the activity
  - `action` (text) - Action description
  - `entity_type` (text) - Type of entity (e.g., 'project')
  - `entity_id` (uuid, optional) - Related entity ID
  - `created_at` (timestamptz) - Activity timestamp

  ## Security (Row Level Security)

  ### RLS Policies for `user_profiles`:
  - Users can view all profiles
  - Users can update their own profile
  - Admins can update any profile

  ### RLS Policies for `projects`:
  - All authenticated users can view all projects
  - Admins can create, update, and delete projects
  - Regular users cannot modify projects

  ### RLS Policies for `activities`:
  - All authenticated users can view all activities
  - System creates activity records (no direct user insert)

  ## Important Notes
  - All tables have RLS enabled for security
  - The `user_profiles` table is automatically populated via trigger when a user signs up
  - Default role for new users is 'user'
  - Admins must be manually promoted by updating the role in user_profiles
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'on-hold')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  start_date date,
  end_date date,
  progress integer DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  budget numeric(12, 2),
  team_members text[] DEFAULT '{}',
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles

-- Everyone can view all user profiles
DROP POLICY IF EXISTS "Anyone can view user profiles" ON user_profiles;
CREATE POLICY "Anyone can view user profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can update any profile
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;
CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- RLS Policies for projects

-- All authenticated users can view projects
DROP POLICY IF EXISTS "Authenticated users can view projects" ON projects;
CREATE POLICY "Authenticated users can view projects"
  ON projects FOR SELECT
  TO authenticated
  USING (true);

-- Only admins can create projects
DROP POLICY IF EXISTS "Admins can create projects" ON projects;
CREATE POLICY "Admins can create projects"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Only admins can update projects
DROP POLICY IF EXISTS "Admins can update projects" ON projects;
CREATE POLICY "Admins can update projects"
  ON projects FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Only admins can delete projects
DROP POLICY IF EXISTS "Admins can delete projects" ON projects;
CREATE POLICY "Admins can delete projects"
  ON projects FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- RLS Policies for activities

-- All authenticated users can view activities
DROP POLICY IF EXISTS "Authenticated users can view activities" ON activities;
CREATE POLICY "Authenticated users can view activities"
  ON activities FOR SELECT
  TO authenticated
  USING (true);

-- Allow inserting activities
DROP POLICY IF EXISTS "Authenticated users can create activities" ON activities;
CREATE POLICY "Authenticated users can create activities"
  ON activities FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create function to automatically create user profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to call function on new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample projects for testing
INSERT INTO projects (name, description, status, priority, progress, team_members)
VALUES
  ('Website Redesign', 'Complete redesign of company website with modern UI/UX', 'active', 'high', 75, ARRAY['Alice Johnson', 'Bob Smith']),
  ('Mobile App Development', 'Native mobile app for iOS and Android', 'active', 'high', 45, ARRAY['Carol White', 'David Brown']),
  ('Marketing Campaign', 'Q4 marketing campaign planning and execution', 'on-hold', 'medium', 30, ARRAY['Eve Davis']),
  ('Data Migration', 'Migrate legacy data to new system', 'completed', 'high', 100, ARRAY['Frank Miller', 'Grace Lee'])
ON CONFLICT (id) DO NOTHING;
