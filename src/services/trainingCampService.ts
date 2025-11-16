import { supabase } from './supabase';
import { filterAdminFighters } from '../utils/filterAdmins';

export interface TrainingCampInvitation {
  id: string;
  inviter_id: string;
  invitee_id: string;
  status: 'pending' | 'accepted' | 'declined' | 'expired' | 'completed';
  started_at: string | null;
  expires_at: string;
  created_at: string;
  updated_at: string;
  message: string | null;
  inviter?: any;
  invitee?: any;
}

export interface CreateTrainingCampInvitationRequest {
  invitee_user_id: string;
  message?: string;
}

class TrainingCampService {
  // Check if fighter can start a training camp (not within 3 days of fight deadline)
  async canStartTrainingCamp(fighterUserId: string): Promise<{ canStart: boolean; reason?: string }> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return { canStart: false, reason: 'Fighter profile not found' };
      }

      // Check if fighter has any scheduled fights within 3 days
      // Since fighters have 1 week to complete fights, we check if there's a fight scheduled
      // within the next 3 days (training camp restriction)
      const threeDaysFromNow = new Date();
      threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

      const { data: upcomingFights, error: fightsError } = await supabase
        .from('scheduled_fights')
        .select('id, scheduled_date, created_at')
        .or(`fighter1_id.eq.${fighter.id},fighter2_id.eq.${fighter.id}`)
        .eq('status', 'Scheduled')
        .gte('scheduled_date', new Date().toISOString())
        .lte('scheduled_date', threeDaysFromNow.toISOString());

      if (fightsError) {
        console.error('Error checking upcoming fights:', fightsError);
        return { canStart: false, reason: 'Error checking fight schedule' };
      }

      if (upcomingFights && upcomingFights.length > 0) {
        const nextFight = upcomingFights[0];
        const fightDate = new Date(nextFight.scheduled_date);
        const daysUntilFight = Math.ceil((fightDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
        
        return { 
          canStart: false, 
          reason: `You have a fight scheduled in ${daysUntilFight} days. Training camps cannot be started within 3 days of a fight.` 
        };
      }

      return { canStart: true };
    } catch (error) {
      console.error('Error in canStartTrainingCamp:', error);
      return { canStart: false, reason: 'Error checking eligibility' };
    }
  }

  // Create a training camp invitation
  async createInvitation(
    inviterUserId: string,
    request: CreateTrainingCampInvitationRequest
  ): Promise<TrainingCampInvitation> {
    try {
      // Check if inviter can start training camp
      const canStart = await this.canStartTrainingCamp(inviterUserId);
      if (!canStart.canStart) {
        throw new Error(canStart.reason || 'Cannot start training camp');
      }

      // Get fighter profile IDs and names
      const { data: inviter, error: inviterError } = await supabase
        .from('fighter_profiles')
        .select('id, name')
        .eq('user_id', inviterUserId)
        .single();

      const { data: invitee, error: inviteeError } = await supabase
        .from('fighter_profiles')
        .select('id, name')
        .eq('user_id', request.invitee_user_id)
        .single();

      if (inviterError || !inviter || inviteeError || !invitee) {
        throw new Error('Fighter profiles not found');
      }

      // Check if there's already a pending invitation
      const { data: existingInvitations, error: checkError } = await supabase
        .from('training_camp_invitations')
        .select('id')
        .eq('inviter_id', inviter.id)
        .eq('invitee_id', invitee.id)
        .eq('status', 'pending')
        .limit(1);
      
      const existingInvitation = existingInvitations && existingInvitations.length > 0 ? existingInvitations[0] : null;

      if (existingInvitation) {
        throw new Error('You have already sent a pending invitation to this fighter');
      }

      // Check if the invitee is a scheduled opponent
      const { data: scheduledFights1, error: fightsError1 } = await supabase
        .from('scheduled_fights')
        .select('id, fighter1_id, fighter2_id, status')
        .eq('fighter1_id', inviter.id)
        .eq('fighter2_id', invitee.id)
        .in('status', ['Scheduled', 'Pending']);

      const { data: scheduledFights2, error: fightsError2 } = await supabase
        .from('scheduled_fights')
        .select('id, fighter1_id, fighter2_id, status')
        .eq('fighter1_id', invitee.id)
        .eq('fighter2_id', inviter.id)
        .in('status', ['Scheduled', 'Pending']);

      if (fightsError1 || fightsError2) {
        console.error('Error checking scheduled fights:', fightsError1 || fightsError2);
      }

      const hasScheduledFight = (scheduledFights1 && scheduledFights1.length > 0) || 
                                (scheduledFights2 && scheduledFights2.length > 0);

      if (hasScheduledFight) {
        throw new Error('You cannot invite a scheduled opponent to a training camp. Training camps are for sparring partners, not opponents.');
      }

      // Check if the invitee is a past opponent (from fight records)
      // Check both directions: inviter's fight records and invitee's fight records
      // Note: fighter_id in fight_records can be either profile ID or user_id, so check both
      const { data: inviterFightRecords, error: inviterRecordsError } = await supabase
        .from('fight_records')
        .select('opponent_name')
        .or(`fighter_id.eq.${inviter.id},fighter_id.eq.${inviterUserId}`)
        .limit(1000);

      const { data: inviteeFightRecords, error: inviteeRecordsError } = await supabase
        .from('fight_records')
        .select('opponent_name')
        .or(`fighter_id.eq.${invitee.id},fighter_id.eq.${request.invitee_user_id}`)
        .limit(1000);

      if (inviterRecordsError) {
        console.error('Error checking inviter fight records:', inviterRecordsError);
      }

      if (inviteeRecordsError) {
        console.error('Error checking invitee fight records:', inviteeRecordsError);
      }

      // Check if invitee's name matches any opponent in inviter's fight records
      if (inviterFightRecords && invitee.name) {
        const inviterOpponentNames = new Set(inviterFightRecords.map(record => record.opponent_name?.toLowerCase().trim()));
        const inviteeNameLower = invitee.name.toLowerCase().trim();
        
        if (inviterOpponentNames.has(inviteeNameLower)) {
          throw new Error('You cannot invite a past opponent to a training camp. Training camps are for sparring partners, not opponents.');
        }
      }

      // Check if inviter's name matches any opponent in invitee's fight records
      if (inviteeFightRecords && inviter?.name) {
        const inviteeOpponentNames = new Set(inviteeFightRecords.map(record => record.opponent_name?.toLowerCase().trim()));
        const inviterNameLower = inviter.name.toLowerCase().trim();
        
        if (inviteeOpponentNames.has(inviterNameLower)) {
          throw new Error('You cannot invite a past opponent to a training camp. Training camps are for sparring partners, not opponents.');
        }
      }

      // Calculate expiration (72 hours from now)
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 72);

      // Create invitation
      const { data: invitation, error: insertError } = await supabase
        .from('training_camp_invitations')
        .insert({
          inviter_id: inviter.id,
          invitee_id: invitee.id,
          status: 'pending',
          expires_at: expiresAt.toISOString(),
          message: request.message || null
        })
        .select('*')
        .single();

      if (insertError) throw insertError;

      // Fetch related fighter profiles separately
      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('id, name, user_id')
        .in('id', [inviter.id, invitee.id]);

      const inviterProfile = fighters?.find(f => f.id === inviter.id);
      const inviteeProfile = fighters?.find(f => f.id === invitee.id);

      // Create notification for invitee
      await supabase
        .from('notifications')
        .insert({
          user_id: request.invitee_user_id,
          type: 'TrainingCamp',
          title: 'Training Camp Invitation',
          message: `You have received a training camp invitation. Check your profile to accept or decline.`,
          action_url: '/profile'
        });

      return {
        ...invitation,
        inviter: inviterProfile || null,
        invitee: inviteeProfile || null
      };
    } catch (error) {
      console.error('Error creating training camp invitation:', error);
      throw error;
    }
  }

  // Accept a training camp invitation
  async acceptInvitation(invitationId: string, inviteeUserId: string): Promise<TrainingCampInvitation> {
    try {
      // Get invitation
      const { data: invitation, error: invitationError } = await supabase
        .from('training_camp_invitations')
        .select('*')
        .eq('id', invitationId)
        .single();

      if (invitationError || !invitation) {
        throw new Error('Invitation not found');
      }

      // Fetch related fighter profiles separately
      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('id, name, user_id')
        .in('id', [invitation.inviter_id, invitation.invitee_id]);

      const inviter = fighters?.find(f => f.id === invitation.inviter_id);
      const invitee = fighters?.find(f => f.id === invitation.invitee_id);

      // Verify invitee
      if (invitee?.user_id !== inviteeUserId) {
        throw new Error('Unauthorized: You are not the invitee');
      }

      // Check if invitation is still valid
      if (invitation.status !== 'pending') {
        throw new Error(`Invitation is ${invitation.status}`);
      }

      if (new Date(invitation.expires_at) < new Date()) {
        throw new Error('Invitation has expired');
      }

      // Check if invitee can start training camp
      const canStart = await this.canStartTrainingCamp(inviteeUserId);
      if (!canStart.canStart) {
        throw new Error(canStart.reason || 'Cannot start training camp');
      }

      // Get fighter profile IDs
      const inviterProfileId = invitation.inviter_id;
      const inviteeProfileId = invitation.invitee_id;

      // Check if inviter already has 3 active sparring partners
      const { data: inviterActiveCamps, error: inviterCampsError } = await supabase
        .from('training_camp_invitations')
        .select('inviter_id, invitee_id')
        .or(`inviter_id.eq.${inviterProfileId},invitee_id.eq.${inviterProfileId}`)
        .eq('status', 'accepted')
        .gte('expires_at', new Date().toISOString());

      if (!inviterCampsError && inviterActiveCamps) {
        const inviterSparringPartners = new Set<string>();
        inviterActiveCamps.forEach(camp => {
          if (camp.inviter_id === inviterProfileId) {
            inviterSparringPartners.add(camp.invitee_id);
          } else if (camp.invitee_id === inviterProfileId) {
            inviterSparringPartners.add(camp.inviter_id);
          }
        });
        
        if (inviterSparringPartners.size >= 3) {
          throw new Error('The inviter already has 3 active sparring partners. Maximum limit reached.');
        }
      }

      // Check if invitee already has 3 active sparring partners
      const { data: inviteeActiveCamps, error: inviteeCampsError } = await supabase
        .from('training_camp_invitations')
        .select('inviter_id, invitee_id')
        .or(`inviter_id.eq.${inviteeProfileId},invitee_id.eq.${inviteeProfileId}`)
        .eq('status', 'accepted')
        .gte('expires_at', new Date().toISOString());

      if (!inviteeCampsError && inviteeActiveCamps) {
        const inviteeSparringPartners = new Set<string>();
        inviteeActiveCamps.forEach(camp => {
          if (camp.inviter_id === inviteeProfileId) {
            inviteeSparringPartners.add(camp.invitee_id);
          } else if (camp.invitee_id === inviteeProfileId) {
            inviteeSparringPartners.add(camp.inviter_id);
          }
        });
        
        if (inviteeSparringPartners.size >= 3) {
          throw new Error('You already have 3 active sparring partners. Maximum limit reached.');
        }
      }

      // Update invitation to accepted and set start time
      const startedAt = new Date();
      const expiresAt = new Date(startedAt);
      expiresAt.setHours(expiresAt.getHours() + 72); // 72 hours from start

      const { data: updatedInvitation, error: updateError } = await supabase
        .from('training_camp_invitations')
        .update({
          status: 'accepted',
          started_at: startedAt.toISOString(),
          expires_at: expiresAt.toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', invitationId)
        .select('*')
        .single();

      if (updateError) throw updateError;

      // Fetch related fighter profiles separately (reuse the ones we already fetched)
      const inviterProfile = fighters?.find(f => f.id === invitation.inviter_id);
      const inviteeProfile = fighters?.find(f => f.id === invitation.invitee_id);

      // Create notifications for both fighters
      await supabase
        .from('notifications')
        .insert([
          {
            user_id: inviterProfile?.user_id,
            type: 'TrainingCamp',
            title: 'Training Camp Accepted',
            message: `${inviteeProfile?.name} has accepted your training camp invitation.`,
            action_url: '/profile'
          },
          {
            user_id: inviteeUserId,
            type: 'TrainingCamp',
            title: 'Training Camp Started',
            message: `Your training camp with ${inviterProfile?.name} has started. It will last 72 hours.`,
            action_url: '/profile'
          }
        ]);

      return {
        ...updatedInvitation,
        inviter: inviterProfile || null,
        invitee: inviteeProfile || null
      };
    } catch (error) {
      console.error('Error accepting training camp invitation:', error);
      throw error;
    }
  }

  // Decline a training camp invitation
  async declineInvitation(invitationId: string, inviteeUserId: string): Promise<void> {
    try {
      // Get invitation
      const { data: invitation, error: invitationError } = await supabase
        .from('training_camp_invitations')
        .select('*')
        .eq('id', invitationId)
        .single();

      if (invitationError || !invitation) {
        throw new Error('Invitation not found');
      }

      // Fetch related fighter profiles separately
      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('id, name, user_id')
        .in('id', [invitation.inviter_id, invitation.invitee_id]);

      const inviteeProfile = fighters?.find(f => f.id === invitation.invitee_id);

      // Verify invitee
      if (inviteeProfile?.user_id !== inviteeUserId) {
        throw new Error('Unauthorized: You are not the invitee');
      }

      // Update invitation to declined
      const { error: updateError } = await supabase
        .from('training_camp_invitations')
        .update({
          status: 'declined',
          updated_at: new Date().toISOString()
        })
        .eq('id', invitationId);

      if (updateError) throw updateError;

      // Create notification for inviter
      const inviterProfile = fighters?.find(f => f.id === invitation.inviter_id);
      await supabase
        .from('notifications')
        .insert({
          user_id: inviterProfile?.user_id || null,
          type: 'TrainingCamp',
          title: 'Training Camp Declined',
          message: `${inviteeProfile?.name} has declined your training camp invitation.`,
          action_url: '/profile'
        });
    } catch (error) {
      console.error('Error declining training camp invitation:', error);
      throw error;
    }
  }

  // Get pending invitations for a fighter
  async getPendingInvitations(fighterUserId: string): Promise<TrainingCampInvitation[]> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return [];
      }

      // Fetch invitations without joins
      const { data: invitations, error: invitationsError } = await supabase
        .from('training_camp_invitations')
        .select('*')
        .eq('invitee_id', fighter.id)
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      if (invitationsError) {
        console.error('Error fetching pending invitations:', invitationsError);
        return [];
      }

      if (!invitations || invitations.length === 0) {
        return [];
      }

      // Fetch fighter profiles separately
      const inviterIds = Array.from(new Set(invitations.map(i => i.inviter_id).filter(Boolean)));
      const inviteeIds = Array.from(new Set(invitations.map(i => i.invitee_id).filter(Boolean)));
      const allFighterIds = Array.from(new Set([...inviterIds, ...inviteeIds]));

      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('id', allFighterIds);

      // Combine data
      return invitations.map(invitation => ({
        ...invitation,
        inviter: fighters?.find(f => f.id === invitation.inviter_id) || null,
        invitee: fighters?.find(f => f.id === invitation.invitee_id) || null,
      }));
    } catch (error) {
      console.error('Error in getPendingInvitations:', error);
      return [];
    }
  }

  // Get active training camps for a fighter
  async getActiveTrainingCamps(fighterUserId: string): Promise<TrainingCampInvitation[]> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return [];
      }

      // Fetch camps without joins
      const { data: camps, error: campsError } = await supabase
        .from('training_camp_invitations')
        .select('*')
        .or(`inviter_id.eq.${fighter.id},invitee_id.eq.${fighter.id}`)
        .eq('status', 'accepted')
        .gte('expires_at', new Date().toISOString())
        .order('started_at', { ascending: false });

      if (campsError) {
        console.error('Error fetching active training camps:', campsError);
        return [];
      }

      if (!camps || camps.length === 0) {
        return [];
      }

      // Fetch fighter profiles separately
      const inviterIds = Array.from(new Set(camps.map(c => c.inviter_id).filter(Boolean)));
      const inviteeIds = Array.from(new Set(camps.map(c => c.invitee_id).filter(Boolean)));
      const allFighterIds = Array.from(new Set([...inviterIds, ...inviteeIds]));

      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('id', allFighterIds);

      // Combine data
      return camps.map(camp => ({
        ...camp,
        inviter: fighters?.find(f => f.id === camp.inviter_id) || null,
        invitee: fighters?.find(f => f.id === camp.invitee_id) || null,
      }));
    } catch (error) {
      console.error('Error in getActiveTrainingCamps:', error);
      return [];
    }
  }

  // Get all active training camps (for HomePage display)
  async getAllActiveTrainingCamps(): Promise<TrainingCampInvitation[]> {
    try {
      // Fetch camps without joins (Supabase can't auto-detect foreign keys)
      // This query should return ALL active training camps in the league
      // RLS policy "Anyone can view active training camps" should allow this
      const { data: camps, error: campsError } = await supabase
        .from('training_camp_invitations')
        .select('*')
        .eq('status', 'accepted')
        .gte('expires_at', new Date().toISOString())
        .order('started_at', { ascending: false });

      if (campsError) {
        console.error('❌ Error fetching all active training camps:', campsError);
        console.error('Error details:', {
          message: campsError.message,
          details: campsError.details,
          hint: campsError.hint,
          code: campsError.code
        });
        
        // Check if this might be an RLS policy issue
        if (campsError.code === '42501' || campsError.message?.includes('permission') || campsError.message?.includes('policy')) {
          console.warn('⚠️ This might be an RLS policy issue. Ensure the "Anyone can view active training camps" policy exists.');
          console.warn('⚠️ Run the SQL script: database/ensure-view-all-active-training-camps-rls.sql');
        }
        
        return [];
      }

      if (!camps || camps.length === 0) {
        console.log('ℹ️ No active training camps found in database');
        console.log('ℹ️ If you expected to see training camps, verify the RLS policy "Anyone can view active training camps" exists.');
        return [];
      }

      console.log(`✅ Found ${camps.length} active training camp(s) in database`);

      // Get unique fighter profile IDs
      const inviterIds = Array.from(new Set(camps.map(c => c.inviter_id).filter(Boolean)));
      const inviteeIds = Array.from(new Set(camps.map(c => c.invitee_id).filter(Boolean)));
      const allProfileIds = Array.from(new Set([...inviterIds, ...inviteeIds]));

      // Fetch all fighter profiles in one query
      const { data: profiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('id', allProfileIds);

      if (profilesError) {
        console.error('Error fetching fighter profiles:', profilesError);
        return [];
      }

      // Create a map for quick lookup
      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      // Combine camps with fighter profiles
      const campsWithProfiles = camps.map(camp => ({
        ...camp,
        inviter: camp.inviter_id ? profileMap.get(camp.inviter_id) : null,
        invitee: camp.invitee_id ? profileMap.get(camp.invitee_id) : null
      }));

      // Filter out camps where we couldn't load fighter profiles (shouldn't happen, but safety check)
      const validCamps = campsWithProfiles.filter(camp => camp.inviter || camp.invitee);
      
      if (validCamps.length !== campsWithProfiles.length) {
        console.warn(`⚠️ Filtered out ${campsWithProfiles.length - validCamps.length} camp(s) due to missing fighter profiles`);
      }

      console.log(`✅ Returning ${validCamps.length} active training camp(s) with fighter profiles`);
      
      // Return all active training camps (including those with admin fighters)
      // This matches the Admin Home Page behavior - showing all League Training Camps
      return validCamps as TrainingCampInvitation[];
    } catch (error) {
      console.error('Error in getAllActiveTrainingCamps:', error);
      return [];
    }
  }

  // Get training camps grouped by fighter with sparring partners
  // Returns an array of objects with fighter info and their sparring partners
  async getTrainingCampsGroupedByFighter(): Promise<Array<{
    fighter: any;
    sparringPartners: Array<{
      partner: any;
      camp: TrainingCampInvitation;
    }>;
    startedAt: string;
    expiresAt: string;
  }>> {
    try {
      const allCamps = await this.getAllActiveTrainingCamps();
      
      // Group camps by fighter (inviter)
      const campsByFighter = new Map<string, {
        fighter: any;
        sparringPartners: Array<{
          partner: any;
          camp: TrainingCampInvitation;
        }>;
        startedAt: string;
        expiresAt: string;
      }>();

      for (const camp of allCamps) {
        const inviterId = camp.inviter_id;
        const inviter = camp.inviter;
        const invitee = camp.invitee;

        if (!inviter || !invitee) continue;

        // Get or create fighter group
        if (!campsByFighter.has(inviterId)) {
          campsByFighter.set(inviterId, {
            fighter: inviter,
            sparringPartners: [],
            startedAt: camp.started_at || camp.created_at,
            expiresAt: camp.expires_at
          });
        }

        const fighterGroup = campsByFighter.get(inviterId)!;
        
        // Add invitee as sparring partner
        fighterGroup.sparringPartners.push({
          partner: invitee,
          camp: camp
        });

        // Also group by invitee (bidirectional)
        const inviteeId = camp.invitee_id;
        if (!campsByFighter.has(inviteeId)) {
          campsByFighter.set(inviteeId, {
            fighter: invitee,
            sparringPartners: [],
            startedAt: camp.started_at || camp.created_at,
            expiresAt: camp.expires_at
          });
        }

        const inviteeGroup = campsByFighter.get(inviteeId)!;
        inviteeGroup.sparringPartners.push({
          partner: inviter,
          camp: camp
        });
      }

      return Array.from(campsByFighter.values());
    } catch (error) {
      console.error('Error in getTrainingCampsGroupedByFighter:', error);
      return [];
    }
  }

  // Helper to check if a fighter is an admin
  private async isAdminFighter(userId: string): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

      if (error || !data) return false;
      return data.role === 'admin';
    } catch (error) {
      return false;
    }
  }

  // Helper to get fighter user_id from profile id
  private async getFighterUserId(profileId: string): Promise<string | null> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('user_id')
      .eq('id', profileId)
      .maybeSingle();

    if (error || !data) return null;
    return data.user_id || null;
  }
}

export const trainingCampService = new TrainingCampService();

