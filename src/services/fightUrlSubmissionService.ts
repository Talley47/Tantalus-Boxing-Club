import { supabase } from './supabase';
import { FightUrlSubmission, CreateFightUrlSubmissionRequest } from '../types';

const TABLE_NAME = 'fight_url_submissions';

class FightUrlSubmissionService {
  // Submit a fight URL to admin
  async submitFightUrl(
    request: CreateFightUrlSubmissionRequest,
    fighterId: string
  ): Promise<FightUrlSubmission> {
    const { data, error } = await supabase
      .from(TABLE_NAME)
      .insert({
        fighter_id: fighterId,
        scheduled_fight_id: request.scheduled_fight_id || null,
        tournament_id: request.tournament_id || null,
        fight_url: request.fight_url.trim(),
        event_type: request.event_type,
        description: request.description?.trim() || null,
        status: 'Pending',
      })
      .select('*')
      .single();

    if (error) {
      console.error('Error submitting fight URL:', error);
      throw error;
    }

    // Fetch related data separately
    const fighterIds = [fighterId];
    const scheduledFightIds = request.scheduled_fight_id ? [request.scheduled_fight_id] : [];
    const tournamentIds = request.tournament_id ? [request.tournament_id] : [];

    // Fetch fighter profile
    const { data: fighters } = await supabase
      .from('fighter_profiles')
      .select('id, name, user_id')
      .in('id', fighterIds);

    // Fetch scheduled fight
    const { data: scheduledFights } = scheduledFightIds.length > 0
      ? await supabase
          .from('scheduled_fights')
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .in('id', scheduledFightIds)
      : { data: [] };

    // Fetch tournament
    const { data: tournaments } = tournamentIds.length > 0
      ? await supabase
          .from('tournaments')
          .select('id, name, format, weight_class, status')
          .in('id', tournamentIds)
      : { data: [] };

    // Combine data
    return {
      ...data,
      fighter: fighters?.[0] || null,
      scheduled_fight: scheduledFights?.[0] || null,
      tournament: tournaments?.[0] || null,
    };
  }

  // Get fight URL submissions for a fighter
  async getFighterSubmissions(fighterId: string): Promise<FightUrlSubmission[]> {
    // Fetch submissions without joins
    const { data: submissions, error } = await supabase
      .from(TABLE_NAME)
      .select('*')
      .eq('fighter_id', fighterId)
      .order('submitted_at', { ascending: false });

    if (error) {
      console.error('Error fetching fighter submissions:', error);
      throw error;
    }

    if (!submissions || submissions.length === 0) {
      return [];
    }

    // Fetch related data separately
    const fighterIds = Array.from(new Set(submissions.map(s => s.fighter_id).filter(Boolean)));
    const scheduledFightIds = Array.from(new Set(submissions.map(s => s.scheduled_fight_id).filter(Boolean)));
    const tournamentIds = Array.from(new Set(submissions.map(s => s.tournament_id).filter(Boolean)));

    // Fetch fighter profiles
    const { data: fighters } = await supabase
      .from('fighter_profiles')
      .select('id, name, user_id')
      .in('id', fighterIds);

    // Fetch scheduled fights
    const { data: scheduledFights } = scheduledFightIds.length > 0
      ? await supabase
          .from('scheduled_fights')
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .in('id', scheduledFightIds)
      : { data: [] };

    // Fetch tournaments
    const { data: tournaments } = tournamentIds.length > 0
      ? await supabase
          .from('tournaments')
          .select('id, name, format, weight_class, status')
          .in('id', tournamentIds)
      : { data: [] };

    // Combine data
    return submissions.map(submission => ({
      ...submission,
      fighter: fighters?.find(f => f.id === submission.fighter_id) || null,
      scheduled_fight: scheduledFights?.find(sf => sf.id === submission.scheduled_fight_id) || null,
      tournament: tournaments?.find(t => t.id === submission.tournament_id) || null,
    }));
  }

  // Get all submissions (admin only)
  async getAllSubmissions(status?: string): Promise<FightUrlSubmission[]> {
    // Fetch submissions without joins
    let query = supabase
      .from(TABLE_NAME)
      .select('*')
      .order('submitted_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const { data: submissions, error } = await query;

    if (error) {
      console.error('Error fetching all submissions:', error);
      throw error;
    }

    if (!submissions || submissions.length === 0) {
      return [];
    }

    // Fetch related data separately
    const fighterIds = Array.from(new Set(submissions.map(s => s.fighter_id).filter(Boolean)));
    const scheduledFightIds = Array.from(new Set(submissions.map(s => s.scheduled_fight_id).filter(Boolean)));
    const tournamentIds = Array.from(new Set(submissions.map(s => s.tournament_id).filter(Boolean)));

    // Fetch fighter profiles
    const { data: fighters } = await supabase
      .from('fighter_profiles')
      .select('id, name, user_id')
      .in('id', fighterIds);

    // Fetch scheduled fights
    const { data: scheduledFights } = scheduledFightIds.length > 0
      ? await supabase
          .from('scheduled_fights')
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .in('id', scheduledFightIds)
      : { data: [] };

    // Fetch tournaments
    const { data: tournaments } = tournamentIds.length > 0
      ? await supabase
          .from('tournaments')
          .select('id, name, format, weight_class, status')
          .in('id', tournamentIds)
      : { data: [] };

    // Combine data
    return submissions.map(submission => ({
      ...submission,
      fighter: fighters?.find(f => f.id === submission.fighter_id) || null,
      scheduled_fight: scheduledFights?.find(sf => sf.id === submission.scheduled_fight_id) || null,
      tournament: tournaments?.find(t => t.id === submission.tournament_id) || null,
    }));
  }

  // Update submission (fighter can update pending, admin can review)
  async updateSubmission(
    submissionId: string,
    updates: {
      fight_url?: string;
      description?: string;
      status?: 'Pending' | 'Reviewed' | 'Rejected' | 'Approved';
      admin_notes?: string;
      reviewed_by?: string;
    }
  ): Promise<FightUrlSubmission> {
    const updateData: any = {
      updated_at: new Date().toISOString(),
    };

    if (updates.fight_url !== undefined) {
      updateData.fight_url = updates.fight_url.trim();
    }
    if (updates.description !== undefined) {
      updateData.description = updates.description?.trim() || null;
    }
    if (updates.status !== undefined) {
      updateData.status = updates.status;
      if (updates.status !== 'Pending') {
        updateData.reviewed_at = new Date().toISOString();
        if (updates.reviewed_by) {
          updateData.reviewed_by = updates.reviewed_by;
        }
      }
    }
    if (updates.admin_notes !== undefined) {
      updateData.admin_notes = updates.admin_notes?.trim() || null;
    }

    const { data, error } = await supabase
      .from(TABLE_NAME)
      .update(updateData)
      .eq('id', submissionId)
      .select('*')
      .single();

    if (error) {
      console.error('Error updating submission:', error);
      throw error;
    }

    // Fetch related data separately
    const fighterIds = [data.fighter_id].filter(Boolean);
    const scheduledFightIds = data.scheduled_fight_id ? [data.scheduled_fight_id] : [];
    const tournamentIds = data.tournament_id ? [data.tournament_id] : [];

    // Fetch fighter profile
    const { data: fighters } = fighterIds.length > 0
      ? await supabase
          .from('fighter_profiles')
          .select('id, name, user_id')
          .in('id', fighterIds)
      : { data: [] };

    // Fetch scheduled fight
    const { data: scheduledFights } = scheduledFightIds.length > 0
      ? await supabase
          .from('scheduled_fights')
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .in('id', scheduledFightIds)
      : { data: [] };

    // Fetch tournament
    const { data: tournaments } = tournamentIds.length > 0
      ? await supabase
          .from('tournaments')
          .select('id, name, format, weight_class, status')
          .in('id', tournamentIds)
      : { data: [] };

    // Combine data
    return {
      ...data,
      fighter: fighters?.[0] || null,
      scheduled_fight: scheduledFights?.[0] || null,
      tournament: tournaments?.[0] || null,
    };
  }

  // Delete a submission (fighter can delete pending submissions)
  async deleteSubmission(submissionId: string): Promise<void> {
    const { error } = await supabase
      .from(TABLE_NAME)
      .delete()
      .eq('id', submissionId);

    if (error) {
      console.error('Error deleting submission:', error);
      throw error;
    }
  }

  // Delete all approved and rejected submissions (admin only)
  async deleteAllApprovedAndRejected(): Promise<number> {
    try {
      console.log('Starting deleteAllApprovedAndRejected...');
      
      // First, get all approved and rejected submissions to count them
      const { data: submissionsToDelete, error: fetchError } = await supabase
        .from(TABLE_NAME)
        .select('id, status')
        .in('status', ['Approved', 'Rejected']);

      if (fetchError) {
        console.error('Error fetching approved/rejected submissions:', fetchError);
        throw fetchError;
      }

      console.log(`Found ${submissionsToDelete?.length || 0} approved/rejected submissions to delete`);

      if (!submissionsToDelete || submissionsToDelete.length === 0) {
        console.log('No approved/rejected submissions found to delete');
        return 0;
      }

      const submissionIds = submissionsToDelete.map(s => s.id);
      console.log('Submissions to delete:', submissionIds);
      console.log('Submission IDs count:', submissionIds.length);

      // Delete all approved and rejected submissions
      // Use a loop for smaller batches to ensure all deletions go through
      // Supabase sometimes has issues with large .in() queries
      const batchSize = 100;
      let totalDeleted = 0;
      
      for (let i = 0; i < submissionIds.length; i += batchSize) {
        const batch = submissionIds.slice(i, i + batchSize);
        console.log(`Deleting batch ${Math.floor(i / batchSize) + 1} of ${Math.ceil(submissionIds.length / batchSize)}: ${batch.length} submissions`);
        
        const { error: deleteError } = await supabase
          .from(TABLE_NAME)
          .delete()
          .in('id', batch);

        if (deleteError) {
          console.error(`Error deleting batch ${Math.floor(i / batchSize) + 1}:`, deleteError);
          throw deleteError;
        }
        
        totalDeleted += batch.length;
        console.log(`Successfully deleted batch ${Math.floor(i / batchSize) + 1}: ${batch.length} submissions`);
      }
      
      console.log(`Total deleted: ${totalDeleted} submissions`);
      
      return totalDeleted;
    } catch (error: any) {
      console.error('Error in deleteAllApprovedAndRejected:', error);
      throw error;
    }
  }
}

export const fightUrlSubmissionService = new FightUrlSubmissionService();

