import { supabase } from './supabase';
import { MediaAsset, Interview, PressConference, SocialLink, TrainingCamp, TrainingObjective, TrainingLog } from '../types';

class MediaService {
  // Media Assets
  async getMediaAssets(fighterId: string): Promise<MediaAsset[]> {
    const { data, error } = await supabase
      .from('media_assets')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data || [];
  }

  async uploadMediaAsset(asset: Partial<MediaAsset>): Promise<MediaAsset> {
    const { data, error } = await supabase
      .from('media_assets')
      .insert(asset)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Interviews
  async getInterviews(fighterId: string): Promise<Interview[]> {
    const { data, error } = await supabase
      .from('interviews')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('scheduled_date', { ascending: false });
    
    if (error) throw error;
    return data || [];
  }

  async scheduleInterview(interview: Partial<Interview>): Promise<Interview> {
    const { data, error } = await supabase
      .from('interviews')
      .insert(interview)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Press Conferences
  async getPressConferences(fighterId: string): Promise<PressConference[]> {
    const { data, error } = await supabase
      .from('press_conferences')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('scheduled_date', { ascending: false });
    
    if (error) throw error;
    return data || [];
  }

  async schedulePressConference(press: Partial<PressConference>): Promise<PressConference> {
    const { data, error } = await supabase
      .from('press_conferences')
      .insert(press)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Social Links
  async getSocialLinks(fighterId: string): Promise<SocialLink[]> {
    const { data, error } = await supabase
      .from('social_links')
      .select('*')
      .eq('fighter_id', fighterId);
    
    if (error) throw error;
    return data || [];
  }

  async addSocialLink(link: Partial<SocialLink>): Promise<SocialLink> {
    const { data, error } = await supabase
      .from('social_links')
      .insert(link)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Training Camps
  async getTrainingCamps(fighterId: string): Promise<TrainingCamp[]> {
    const { data, error } = await supabase
      .from('training_camps')
      .select('*')
      .eq('created_by', fighterId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data || [];
  }

  async createTrainingCamp(camp: Partial<TrainingCamp>): Promise<TrainingCamp> {
    const { data, error } = await supabase
      .from('training_camps')
      .insert(camp)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Training Objectives
  async getTrainingObjectives(campId: string): Promise<TrainingObjective[]> {
    const { data, error } = await supabase
      .from('training_objectives')
      .select('*')
      .eq('camp_id', campId)
      .order('order_index', { ascending: true });
    
    if (error) throw error;
    return data || [];
  }

  async createTrainingObjective(objective: Partial<TrainingObjective>): Promise<TrainingObjective> {
    const { data, error } = await supabase
      .from('training_objectives')
      .insert(objective)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  // Training Logs
  async getTrainingLogs(fighterId: string): Promise<TrainingLog[]> {
    const { data, error } = await supabase
      .from('training_logs')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('completed_at', { ascending: false });
    
    if (error) throw error;
    return data || [];
  }

  async logTraining(log: Partial<TrainingLog>): Promise<TrainingLog> {
    const { data, error } = await supabase
      .from('training_logs')
      .insert(log)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }
}

export const mediaService = new MediaService();
export default mediaService;