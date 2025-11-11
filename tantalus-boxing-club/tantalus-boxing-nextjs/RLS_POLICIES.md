# Row Level Security (RLS) Policies

This document outlines the RLS policies that need to be implemented in Supabase for the Tantalus Boxing Club application.

## Overview

RLS policies ensure that users can only access data they're authorized to see. Each table should have appropriate policies based on user roles and data ownership.

## Table Policies

### 1. profiles
```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 2. fighter_profiles
```sql
-- Enable RLS
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own fighter profile
CREATE POLICY "Users can view own fighter profile" ON fighter_profiles
  FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own fighter profile
CREATE POLICY "Users can update own fighter profile" ON fighter_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own fighter profile
CREATE POLICY "Users can insert own fighter profile" ON fighter_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Anyone can view public fighter profiles (for rankings, matchmaking)
CREATE POLICY "Public fighter profiles are viewable" ON fighter_profiles
  FOR SELECT USING (true);

-- Admins can manage all fighter profiles
CREATE POLICY "Admins can manage all fighter profiles" ON fighter_profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 3. fight_records
```sql
-- Enable RLS
ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;

-- Users can view their own fight records
CREATE POLICY "Users can view own fight records" ON fight_records
  FOR SELECT USING (auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id));

-- Users can insert their own fight records
CREATE POLICY "Users can insert own fight records" ON fight_records
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can update their own fight records
CREATE POLICY "Users can update own fight records" ON fight_records
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Anyone can view public fight records (for rankings, statistics)
CREATE POLICY "Public fight records are viewable" ON fight_records
  FOR SELECT USING (true);

-- Admins can manage all fight records
CREATE POLICY "Admins can manage all fight records" ON fight_records
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 4. tournaments
```sql
-- Enable RLS
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;

-- Anyone can view tournaments
CREATE POLICY "Tournaments are publicly viewable" ON tournaments
  FOR SELECT USING (true);

-- Authenticated users can create tournaments
CREATE POLICY "Authenticated users can create tournaments" ON tournaments
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Tournament creators can update their tournaments
CREATE POLICY "Tournament creators can update their tournaments" ON tournaments
  FOR UPDATE USING (auth.uid() = created_by);

-- Admins can manage all tournaments
CREATE POLICY "Admins can manage all tournaments" ON tournaments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 5. tournament_participants
```sql
-- Enable RLS
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Users can view their own tournament participations
CREATE POLICY "Users can view own tournament participations" ON tournament_participants
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can join tournaments
CREATE POLICY "Users can join tournaments" ON tournament_participants
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Tournament creators and admins can manage participants
CREATE POLICY "Tournament creators can manage participants" ON tournament_participants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM tournaments 
      WHERE id = tournament_id AND created_by = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 6. matchmaking_requests
```sql
-- Enable RLS
ALTER TABLE matchmaking_requests ENABLE ROW LEVEL SECURITY;

-- Users can view their own matchmaking requests
CREATE POLICY "Users can view own matchmaking requests" ON matchmaking_requests
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can create their own matchmaking requests
CREATE POLICY "Users can create own matchmaking requests" ON matchmaking_requests
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can update their own matchmaking requests
CREATE POLICY "Users can update own matchmaking requests" ON matchmaking_requests
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Admins can view all matchmaking requests
CREATE POLICY "Admins can view all matchmaking requests" ON matchmaking_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 7. media_assets
```sql
-- Enable RLS
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;

-- Users can view their own media assets
CREATE POLICY "Users can view own media assets" ON media_assets
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own media assets
CREATE POLICY "Users can create own media assets" ON media_assets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own media assets
CREATE POLICY "Users can update own media assets" ON media_assets
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own media assets
CREATE POLICY "Users can delete own media assets" ON media_assets
  FOR DELETE USING (auth.uid() = user_id);

-- Anyone can view public media assets
CREATE POLICY "Public media assets are viewable" ON media_assets
  FOR SELECT USING (true);

-- Admins can manage all media assets
CREATE POLICY "Admins can manage all media assets" ON media_assets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 8. training_camps
```sql
-- Enable RLS
ALTER TABLE training_camps ENABLE ROW LEVEL SECURITY;

-- Anyone can view training camps
CREATE POLICY "Training camps are publicly viewable" ON training_camps
  FOR SELECT USING (true);

-- Authenticated users can create training camps
CREATE POLICY "Authenticated users can create training camps" ON training_camps
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Camp creators can update their camps
CREATE POLICY "Camp creators can update their camps" ON training_camps
  FOR UPDATE USING (auth.uid() = created_by);

-- Admins can manage all training camps
CREATE POLICY "Admins can manage all training camps" ON training_camps
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 9. training_camp_participants
```sql
-- Enable RLS
ALTER TABLE training_camp_participants ENABLE ROW LEVEL SECURITY;

-- Users can view their own camp participations
CREATE POLICY "Users can view own camp participations" ON training_camp_participants
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can join training camps
CREATE POLICY "Users can join training camps" ON training_camp_participants
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Camp creators and admins can manage participants
CREATE POLICY "Camp creators and admins can manage participants" ON training_camp_participants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM training_camps 
      WHERE id = camp_id AND created_by = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 10. disputes
```sql
-- Enable RLS
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- Users can view their own disputes
CREATE POLICY "Users can view own disputes" ON disputes
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own disputes
CREATE POLICY "Users can create own disputes" ON disputes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own disputes (if not resolved)
CREATE POLICY "Users can update own unresolved disputes" ON disputes
  FOR UPDATE USING (auth.uid() = user_id AND status != 'resolved');

-- Admins can view all disputes
CREATE POLICY "Admins can view all disputes" ON disputes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can resolve disputes
CREATE POLICY "Admins can resolve disputes" ON disputes
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 11. interviews
```sql
-- Enable RLS
ALTER TABLE interviews ENABLE ROW LEVEL SECURITY;

-- Users can view their own interviews
CREATE POLICY "Users can view own interviews" ON interviews
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can create their own interviews
CREATE POLICY "Users can create own interviews" ON interviews
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can update their own interviews
CREATE POLICY "Users can update own interviews" ON interviews
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Anyone can view public interviews
CREATE POLICY "Public interviews are viewable" ON interviews
  FOR SELECT USING (true);

-- Admins can manage all interviews
CREATE POLICY "Admins can manage all interviews" ON interviews
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 12. training_logs
```sql
-- Enable RLS
ALTER TABLE training_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their own training logs
CREATE POLICY "Users can view own training logs" ON training_logs
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can create their own training logs
CREATE POLICY "Users can create own training logs" ON training_logs
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can update their own training logs
CREATE POLICY "Users can update own training logs" ON training_logs
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Users can delete their own training logs
CREATE POLICY "Users can delete own training logs" ON training_logs
  FOR DELETE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id)
  );

-- Admins can view all training logs
CREATE POLICY "Admins can view all training logs" ON training_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 13. system_settings
```sql
-- Enable RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Only admins can view system settings
CREATE POLICY "Only admins can view system settings" ON system_settings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update system settings
CREATE POLICY "Only admins can update system settings" ON system_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can insert system settings
CREATE POLICY "Only admins can insert system settings" ON system_settings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 14. user_suspensions
```sql
-- Enable RLS
ALTER TABLE user_suspensions ENABLE ROW LEVEL SECURITY;

-- Users can view their own suspensions
CREATE POLICY "Users can view own suspensions" ON user_suspensions
  FOR SELECT USING (auth.uid() = user_id);

-- Only admins can create suspensions
CREATE POLICY "Only admins can create suspensions" ON user_suspensions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update suspensions
CREATE POLICY "Only admins can update suspensions" ON user_suspensions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can view all suspensions
CREATE POLICY "Only admins can view all suspensions" ON user_suspensions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

## Implementation Notes

1. **Role-based Access**: The policies assume a `role` field in the `profiles` table with values: `user`, `moderator`, `admin`.

2. **Authentication**: All policies use `auth.uid()` to get the current user's ID.

3. **Public Data**: Some tables (like `fighter_profiles`, `fight_records`, `tournaments`) have public read access for rankings and matchmaking.

4. **Admin Override**: Admins have full access to most tables for management purposes.

5. **Data Ownership**: Users can only modify data they own (their own profiles, fight records, etc.).

## Testing RLS Policies

After implementing these policies, test with different user roles:

1. **Regular User**: Should only see their own data and public data
2. **Admin User**: Should see all data and be able to modify everything
3. **Unauthenticated**: Should only see public data (if any)

## Security Considerations

- Always test policies thoroughly
- Use Supabase's built-in policy testing tools
- Monitor for policy violations in logs
- Regularly audit access patterns
- Consider implementing additional security measures for sensitive operations

