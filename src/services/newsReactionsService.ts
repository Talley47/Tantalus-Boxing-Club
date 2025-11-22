import { supabase } from './supabase';

export type ReactionType = 'like' | 'dislike' | 'love' | 'laugh' | 'angry' | 'sad' | 'wow' | 'fire';

export interface NewsReaction {
  id: string;
  news_id: string;
  user_id: string;
  reaction_type: ReactionType;
  created_at: string;
}

export interface ReactionCounts {
  [key: string]: number; // reaction_type -> count
}

export interface UserReaction {
  reaction_type: ReactionType | null;
}

export class NewsReactionsService {
  // Get reaction counts for a news item
  static async getReactionCounts(newsId: string): Promise<ReactionCounts> {
    try {
      const { data, error } = await supabase.rpc('get_news_reaction_counts', {
        p_news_id: newsId,
      });

      if (error) throw error;

      const counts: ReactionCounts = {};
      if (data) {
        data.forEach((row: { reaction_type: ReactionType; count: number }) => {
          counts[row.reaction_type] = row.count;
        });
      }

      return counts;
    } catch (error) {
      console.error('Error fetching reaction counts:', error);
      return {};
    }
  }

  // Get user's reaction for a news item
  static async getUserReaction(newsId: string, userId: string): Promise<ReactionType | null> {
    try {
      const { data, error } = await supabase.rpc('get_user_news_reaction', {
        p_news_id: newsId,
        p_user_id: userId,
      });

      if (error) throw error;

      return data && data.length > 0 ? data[0].reaction_type : null;
    } catch (error) {
      console.error('Error fetching user reaction:', error);
      return null;
    }
  }

  // Add or update a reaction
  static async addReaction(newsId: string, userId: string, reactionType: ReactionType): Promise<void> {
    try {
      // First, check if user already has a reaction
      const existingReaction = await this.getUserReaction(newsId, userId);

      if (existingReaction === reactionType) {
        // User clicked the same reaction - remove it
        await this.removeReaction(newsId, userId, reactionType);
        return;
      }

      if (existingReaction) {
        // Update existing reaction
        const { error } = await supabase
          .from('news_reactions')
          .update({ reaction_type: reactionType })
          .eq('news_id', newsId)
          .eq('user_id', userId)
          .eq('reaction_type', existingReaction);

        if (error) throw error;
      } else {
        // Insert new reaction
        const { error } = await supabase
          .from('news_reactions')
          .insert({
            news_id: newsId,
            user_id: userId,
            reaction_type: reactionType,
          });

        if (error) throw error;
      }
    } catch (error) {
      console.error('Error adding reaction:', error);
      throw error;
    }
  }

  // Remove a reaction
  static async removeReaction(newsId: string, userId: string, reactionType: ReactionType): Promise<void> {
    try {
      const { error } = await supabase
        .from('news_reactions')
        .delete()
        .eq('news_id', newsId)
        .eq('user_id', userId)
        .eq('reaction_type', reactionType);

      if (error) throw error;
    } catch (error) {
      console.error('Error removing reaction:', error);
      throw error;
    }
  }

  // Get all reactions for a news item (for admin/debugging)
  static async getReactions(newsId: string): Promise<NewsReaction[]> {
    try {
      const { data, error } = await supabase
        .from('news_reactions')
        .select('*')
        .eq('news_id', newsId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching reactions:', error);
      return [];
    }
  }
}

