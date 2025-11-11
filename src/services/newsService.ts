import { supabase, TABLES } from './supabase';

export interface NewsItem {
  id: string;
  title: string;
  content: string;
  author: string;
  author_title?: string;
  type: 'news' | 'announcement' | 'blog' | 'fight_result';
  priority: 'high' | 'medium' | 'low';
  images?: string[];
  featured_image?: string;
  tags?: string[];
  is_featured?: boolean;
  is_published?: boolean;
  published_at?: string;
  created_by?: string;
  created_at: string;
  updated_at?: string;
  fight_results?: NewsFightResult[];
}

export interface NewsFightResult {
  id: string;
  news_id: string;
  fight_id?: string;
  fighter1_id?: string;
  fighter2_id?: string;
  winner_id?: string;
  result_method?: string;
  round?: number;
  fighter1_name?: string;
  fighter2_name?: string;
  winner_name?: string;
}

export interface CreateNewsRequest {
  title: string;
  content: string;
  author?: string;
  author_title?: string;
  type: 'news' | 'announcement' | 'blog' | 'fight_result';
  priority?: 'high' | 'medium' | 'low';
  images?: string[];
  featured_image?: string;
  tags?: string[];
  is_featured?: boolean;
  is_published?: boolean;
  published_at?: string;
  fight_results?: Omit<NewsFightResult, 'id' | 'news_id' | 'created_at'>[];
}

export class NewsService {
  // Get all published news items
  static async getNewsItems(
    limit: number = 50,
    type?: NewsItem['type'],
    includeUnpublished: boolean = false
  ): Promise<NewsItem[]> {
    try {
      let query = supabase
        .from('news_announcements')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (!includeUnpublished) {
        // Try to filter by is_published, but handle gracefully if column doesn't exist
        query = query.eq('is_published', true);
      }

      if (type) {
        query = query.eq('type', type);
      }

      const { data, error } = await query;

      if (error) {
        // If error is related to is_published column, try without it
        if (error.message?.includes('is_published') || error.code === '42703') {
          console.warn('is_published column may not exist, retrying without filter');
          let retryQuery = supabase
            .from('news_announcements')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(limit);
          
          if (type) {
            retryQuery = retryQuery.eq('type', type);
          }
          
          const { data: retryData, error: retryError } = await retryQuery;
          if (retryError) {
            console.error('Error fetching news items (retry failed):', retryError);
            return []; // Return empty array instead of throwing
          }
          
          const newsWithFightResults = await Promise.all(
            (retryData || []).map(async (item) => {
              if (item.type === 'fight_result') {
                try {
                  const fightResults = await this.getFightResultsForNews(item.id);
                  return { ...item, fight_results: fightResults };
                } catch (e) {
                  console.warn('Failed to fetch fight results for news item:', item.id);
                  return item;
                }
              }
              return item;
            })
          );
          
          return newsWithFightResults;
        }
        console.error('Error fetching news items:', error);
        return []; // Return empty array instead of throwing to prevent breaking the page
      }

      // Get fight results for fight_result type news
      const newsWithFightResults = await Promise.all(
        (data || []).map(async (item) => {
          if (item.type === 'fight_result') {
            try {
              const fightResults = await this.getFightResultsForNews(item.id);
              return { ...item, fight_results: fightResults };
            } catch (e) {
              // If fight results fetch fails, just return item without results
              console.warn('Failed to fetch fight results for news item:', item.id);
              return item;
            }
          }
          return item;
        })
      );

      return newsWithFightResults;
    } catch (error) {
      console.error('Error fetching news items:', error);
      // Return empty array instead of throwing to prevent breaking the page
      return [];
    }
  }

  // Get news item by ID
  static async getNewsItemById(id: string): Promise<NewsItem | null> {
    try {
      const { data, error } = await supabase
        .from('news_announcements')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;

      if (!data) return null;

      const newsItem: NewsItem = { ...data };

      // Get fight results if applicable
      if (newsItem.type === 'fight_result') {
        newsItem.fight_results = await this.getFightResultsForNews(id);
      }

      return newsItem;
    } catch (error) {
      console.error('Error fetching news item:', error);
      return null;
    }
  }

  // Get fight results for a news item
  static async getFightResultsForNews(newsId: string): Promise<NewsFightResult[]> {
    try {
      const { data, error } = await supabase
        .from('news_fight_results')
        .select('*')
        .eq('news_id', newsId);

      if (error) throw error;

      // Enrich with fighter names
      const enriched = await Promise.all(
        (data || []).map(async (result) => {
          const fighterNames: { [key: string]: string } = {};

          if (result.fighter1_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', result.fighter1_id)
              .single();
            fighterNames[result.fighter1_id] = data?.name || 'Unknown';
          }

          if (result.fighter2_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', result.fighter2_id)
              .single();
            fighterNames[result.fighter2_id] = data?.name || 'Unknown';
          }

          if (result.winner_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', result.winner_id)
              .single();
            fighterNames[result.winner_id] = data?.name || 'Unknown';
          }

          return {
            ...result,
            fighter1_name: result.fighter1_id ? fighterNames[result.fighter1_id] : undefined,
            fighter2_name: result.fighter2_id ? fighterNames[result.fighter2_id] : undefined,
            winner_name: result.winner_id ? fighterNames[result.winner_id] : undefined,
          };
        })
      );

      return enriched;
    } catch (error) {
      console.error('Error fetching fight results:', error);
      return [];
    }
  }

  // Create news item
  static async createNewsItem(news: CreateNewsRequest): Promise<NewsItem> {
    try {
      const newsData: any = {
        title: news.title,
        content: news.content,
        author: news.author || 'Mike Glove',
        author_title: news.author_title || 'TBC News Reporter',
        type: news.type,
        priority: news.priority || 'low',
        images: news.images || [],
        featured_image: news.featured_image,
        tags: news.tags || [],
        is_featured: news.is_featured || false,
        is_published: news.is_published !== false,
        published_at: news.published_at || (news.is_published !== false ? new Date().toISOString() : null),
      };

      const { data, error } = await supabase
        .from('news_announcements')
        .insert(newsData)
        .select()
        .single();

      if (error) throw error;

      // Create fight results if provided
      if (news.fight_results && news.fight_results.length > 0) {
        await Promise.all(
          news.fight_results.map(async (fightResult) => {
            const { error: frError } = await supabase
              .from('news_fight_results')
              .insert({
                news_id: data.id,
                fight_id: fightResult.fight_id,
                fighter1_id: fightResult.fighter1_id,
                fighter2_id: fightResult.fighter2_id,
                winner_id: fightResult.winner_id,
                result_method: fightResult.result_method,
                round: fightResult.round,
              });

            if (frError) throw frError;
          })
        );
      }

      return await this.getNewsItemById(data.id) || data;
    } catch (error) {
      console.error('Error creating news item:', error);
      throw error;
    }
  }

  // Update news item
  static async updateNewsItem(id: string, updates: Partial<CreateNewsRequest>): Promise<NewsItem> {
    try {
      const updateData: any = {};

      if (updates.title !== undefined) updateData.title = updates.title;
      if (updates.content !== undefined) updateData.content = updates.content;
      if (updates.author !== undefined) updateData.author = updates.author;
      if (updates.author_title !== undefined) updateData.author_title = updates.author_title;
      if (updates.type !== undefined) updateData.type = updates.type;
      if (updates.priority !== undefined) updateData.priority = updates.priority;
      if (updates.images !== undefined) updateData.images = updates.images;
      if (updates.featured_image !== undefined) updateData.featured_image = updates.featured_image;
      if (updates.tags !== undefined) updateData.tags = updates.tags;
      if (updates.is_featured !== undefined) updateData.is_featured = updates.is_featured;
      if (updates.is_published !== undefined) {
        updateData.is_published = updates.is_published;
        // Set published_at when publishing, preserve existing if already published
        if (updates.is_published && !updates.published_at) {
          // Check if already published to avoid overwriting
          const { data: existing } = await supabase
            .from('news_announcements')
            .select('published_at')
            .eq('id', id)
            .single();
          
          if (!existing?.published_at) {
            updateData.published_at = new Date().toISOString();
          }
        } else if (!updates.is_published) {
          // Unpublish - clear published_at
          updateData.published_at = null;
        }
      }
      if (updates.published_at !== undefined) updateData.published_at = updates.published_at;

      const { error } = await supabase
        .from('news_announcements')
        .update(updateData)
        .eq('id', id);

      if (error) throw error;

      // Update fight results if provided
      if (updates.fight_results !== undefined) {
        // Delete existing fight results
        await supabase.from('news_fight_results').delete().eq('news_id', id);

        // Insert new fight results
        if (updates.fight_results.length > 0) {
          await Promise.all(
            updates.fight_results.map(async (fightResult) => {
              const { error: frError } = await supabase
                .from('news_fight_results')
                .insert({
                  news_id: id,
                  fight_id: fightResult.fight_id,
                  fighter1_id: fightResult.fighter1_id,
                  fighter2_id: fightResult.fighter2_id,
                  winner_id: fightResult.winner_id,
                  result_method: fightResult.result_method,
                  round: fightResult.round,
                });

              if (frError) throw frError;
            })
          );
        }
      }

      return await this.getNewsItemById(id) || { id } as NewsItem;
    } catch (error) {
      console.error('Error updating news item:', error);
      throw error;
    }
  }

  // Delete news item
  static async deleteNewsItem(id: string): Promise<void> {
    try {
      // First verify the news item exists and we can read it
      const { data: existingItem, error: readError } = await supabase
        .from('news_announcements')
        .select('id, title')
        .eq('id', id)
        .maybeSingle();

      if (readError) {
        console.error('Error reading news item before delete:', readError);
        throw new Error(`Failed to read news item: ${readError.message || readError.code || 'Unknown error'}`);
      }

      if (!existingItem) {
        throw new Error('News item not found.');
      }

      // First, delete related fight results (though CASCADE should handle this)
      // This ensures we can see any errors before attempting to delete the news item
      const { error: fightResultsError } = await supabase
        .from('news_fight_results')
        .delete()
        .eq('news_id', id);

      if (fightResultsError) {
        console.warn('Error deleting related fight results (may not exist):', fightResultsError);
        // Continue anyway as the news item might not have fight results
      }

      // Delete the news item
      const { error, data } = await supabase
        .from('news_announcements')
        .delete()
        .eq('id', id)
        .select();

      if (error) {
        console.error('Error deleting news item:', error);
        console.error('Error details:', {
          code: error.code,
          message: error.message,
          details: error.details,
          hint: error.hint
        });
        throw new Error(`Failed to delete news: ${error.message || error.code || 'Unknown error'}. ${error.hint || ''}`);
      }

      // Check if anything was actually deleted
      if (!data || data.length === 0) {
        // This usually means RLS blocked the delete
        console.error('Delete operation returned no data - likely RLS policy issue');
        throw new Error('News item could not be deleted. This may be due to insufficient permissions. Please ensure you are logged in as an admin.');
      }
    } catch (error: any) {
      console.error('Error deleting news item:', error);
      throw error instanceof Error ? error : new Error(`Failed to delete news: ${error?.message || 'Unknown error'}`);
    }
  }

  // Get recent fight results for auto-news generation
  static async getRecentFightResults(limit: number = 10): Promise<any[]> {
    try {
      const { data, error } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select(`
          *,
          fighter:fighter_profiles!fighter_id (name, id)
        `)
        .order('date', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching recent fight results:', error);
      return [];
    }
  }

  // Auto-generate news post from fight results
  static async autoGenerateFightResultsNews(fightIds: string[]): Promise<NewsItem | null> {
    try {
      // Get fight records
      const { data: fights, error } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select(`
          *,
          fighter:fighter_profiles!fighter_id (name, id)
        `)
        .in('id', fightIds)
        .order('date', { ascending: false });

      if (error || !fights || fights.length === 0) {
        throw new Error('No fight results found');
      }

      // Build content
      const content = `Latest Fight Results:\n\n${fights.map((fight: any) => 
        `• ${fight.fighter?.name || 'Fighter'} defeated ${fight.opponent_name} via ${fight.method}${fight.round ? ` (Round ${fight.round})` : ''}`
      ).join('\n')}`;

      const fightResults = fights.map((fight: any) => ({
        fighter1_id: fight.fighter_id,
        fighter2_id: undefined,
        winner_id: fight.result === 'Win' ? fight.fighter_id : undefined,
        result_method: fight.method,
        round: fight.round,
      }));

      const now = new Date();
      const newsData: CreateNewsRequest = {
        title: `Latest Fight Results - ${now.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`,
        content: content,
        author: 'Mike Glove',
        author_title: 'TBC News Reporter',
        type: 'fight_result',
        priority: 'medium',
        tags: ['Fight Results', 'Latest'],
        is_published: true,
        published_at: now.toISOString(),
        fight_results: fightResults,
      };

      return await this.createNewsItem(newsData);
    } catch (error) {
      console.error('Error auto-generating fight results news:', error);
      throw error;
    }
  }
}

