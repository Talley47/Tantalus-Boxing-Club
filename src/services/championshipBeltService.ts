import { supabase } from './supabase';

export type GoverningBody = 
  | 'TBA_AMATEUR'      // TBA Tantalus Boxing Amateur Association
  | 'TBA_ASSOCIATION'  // TBA Tantalus Boxing Association
  | 'TBC_COUNCIL'      // TBC Tantalus Boxing Council
  | 'TBF_FEDERATION'   // TBF Tantalus Boxing Federation
  | 'TBO_WORLD'        // TBO Tantalus World Boxing Organization
  | 'RING_MAGAZINE';   // Tantalus Ring Magazine

export interface ChampionshipBelt {
  id: string;
  fighter_id: string;
  user_id: string;
  governing_body: GoverningBody;
  belt_image_url: string;
  created_at: string;
  updated_at: string;
  created_by?: string;
}

export interface CreateChampionshipBeltRequest {
  fighter_id: string;
  user_id: string;
  governing_body: GoverningBody;
  belt_image_url: string;
}

export const GOVERNING_BODY_LABELS: Record<GoverningBody, string> = {
  TBA_AMATEUR: 'TBA Tantalus Boxing Amateur Association',
  TBA_ASSOCIATION: 'TBA Tantalus Boxing Association',
  TBC_COUNCIL: 'TBC Tantalus Boxing Council',
  TBF_FEDERATION: 'TBF Tantalus Boxing Federation',
  TBO_WORLD: 'TBO Tantalus World Boxing Organization',
  RING_MAGAZINE: 'Tantalus Ring Magazine',
};

class ChampionshipBeltService {
  private readonly TABLE_NAME = 'championship_belts';
  private readonly STORAGE_BUCKET = 'championship-belts';

  /**
   * Check if the storage bucket exists
   */
  async checkBucketExists(): Promise<boolean> {
    try {
      const { data, error } = await supabase.storage.listBuckets();
      if (error) {
        console.error('Error checking buckets:', error);
        return false;
      }
      return data?.some(bucket => bucket.name === this.STORAGE_BUCKET) || false;
    } catch (error) {
      console.error('Error checking bucket existence:', error);
      return false;
    }
  }

  /**
   * Upload a championship belt image to Supabase Storage
   */
  async uploadBeltImage(file: File, fighterId: string): Promise<string> {
    const fileExt = file.name.split('.').pop();
    const fileName = `${fighterId}/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
    const filePath = fileName;

    const { data, error } = await supabase.storage
      .from(this.STORAGE_BUCKET)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      });

    if (error) {
      console.error('Error uploading championship belt image:', error);
      
      // Check for bucket not found error
      if (error.message?.includes('Bucket not found') || 
          error.message?.includes('not found') ||
          error.message?.toLowerCase().includes('bucket')) {
        throw new Error(
          `Storage bucket "championship-belts" not found!\n\n` +
          `If you just created it, try:\n` +
          `1. Hard refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)\n` +
          `2. Wait 10-30 seconds for Supabase to sync\n` +
          `3. Verify the bucket exists in Supabase Dashboard > Storage\n` +
          `4. Make sure it's set to "Public"\n\n` +
          `If the bucket doesn't exist, create it:\n` +
          `- Go to Supabase Dashboard > Storage\n` +
          `- Click "New bucket"\n` +
          `- Name: "championship-belts" (exact, lowercase, with hyphen)\n` +
          `- Check "Public bucket" ✅\n` +
          `- File size limit: 10 MB\n` +
          `- MIME types: image/jpeg, image/jpg, image/png, image/gif, image/webp\n` +
          `- Then run: setup-championship-belts-storage.sql in SQL Editor`
        );
      }
      
      // Check for RLS/policy errors
      if (error.message?.includes('row-level security') || 
          error.message?.includes('RLS') || 
          error.message?.includes('policy') ||
          error.message?.includes('permission') ||
          error.message?.includes('403') ||
          error.message?.includes('Forbidden')) {
        throw new Error(
          `Storage bucket permission error!\n\n` +
          `Please run: setup-championship-belts-storage.sql in Supabase SQL Editor\n\n` +
          `Also verify:\n` +
          `- You're logged in as an admin user\n` +
          `- The bucket is set to "Public"\n` +
          `- Storage policies were created successfully`
        );
      }
      
      throw error;
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from(this.STORAGE_BUCKET)
      .getPublicUrl(filePath);

    return publicUrl;
  }

  /**
   * Delete a championship belt image from Supabase Storage
   */
  async deleteBeltImage(imageUrl: string): Promise<void> {
    try {
      // Extract the file path from the URL
      // URL format: https://[project].supabase.co/storage/v1/object/public/championship-belts/[path]
      const urlParts = imageUrl.split('/championship-belts/');
      if (urlParts.length < 2) {
        throw new Error('Invalid image URL format');
      }
      const filePath = urlParts[1];

      const { error } = await supabase.storage
        .from(this.STORAGE_BUCKET)
        .remove([filePath]);

      if (error) {
        console.error('Error deleting championship belt image:', error);
        throw error;
      }
    } catch (error: any) {
      console.error('Error deleting belt image:', error);
      // Don't throw - image deletion failure shouldn't prevent belt deletion
      console.warn('Continuing with belt deletion despite image deletion error');
    }
  }

  /**
   * Create a championship belt for a fighter
   */
  async createBelt(request: CreateChampionshipBeltRequest): Promise<ChampionshipBelt> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      throw new Error('User must be authenticated');
    }

    const { data, error } = await supabase
      .from(this.TABLE_NAME)
      .insert({
        ...request,
        created_by: user.id,
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating championship belt:', error);
      throw error;
    }

    return data;
  }

  /**
   * Get all championship belts for a fighter
   */
  async getBeltsByFighterId(fighterId: string): Promise<ChampionshipBelt[]> {
    const { data, error } = await supabase
      .from(this.TABLE_NAME)
      .select('*')
      .eq('fighter_id', fighterId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching championship belts:', error);
      throw error;
    }

    return data || [];
  }

  /**
   * Get all championship belts for a user (by user_id)
   */
  async getBeltsByUserId(userId: string): Promise<ChampionshipBelt[]> {
    const { data, error } = await supabase
      .from(this.TABLE_NAME)
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching championship belts:', error);
      throw error;
    }

    return data || [];
  }

  /**
   * Delete a championship belt
   */
  async deleteBelt(beltId: string): Promise<void> {
    // First, get the belt to get the image URL
    const { data: belt, error: fetchError } = await supabase
      .from(this.TABLE_NAME)
      .select('belt_image_url')
      .eq('id', beltId)
      .single();

    if (fetchError) {
      console.error('Error fetching belt for deletion:', fetchError);
      throw fetchError;
    }

    // Delete the belt record
    const { error } = await supabase
      .from(this.TABLE_NAME)
      .delete()
      .eq('id', beltId);

    if (error) {
      console.error('Error deleting championship belt:', error);
      throw error;
    }

    // Delete the image from storage (don't throw if this fails)
    if (belt?.belt_image_url) {
      await this.deleteBeltImage(belt.belt_image_url);
    }
  }

  /**
   * Get all championship belts (admin use)
   */
  async getAllBelts(): Promise<ChampionshipBelt[]> {
    const { data, error } = await supabase
      .from(this.TABLE_NAME)
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching all championship belts:', error);
      throw error;
    }

    return data || [];
  }

  /**
   * Get fighter profile ID from user ID
   */
  async getFighterProfileId(userId: string): Promise<string | null> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (error) {
      console.error('Error fetching fighter profile:', error);
      throw error;
    }

    return data?.id || null;
  }
}

export const championshipBeltService = new ChampionshipBeltService();

