import { supabase } from './supabase';
import { Dispute, DisputeMessage, FightRecordSubmission } from '../types';
import { schedulingService } from './schedulingService';

const TABLES = {
  DISPUTES: 'disputes',
  DISPUTE_MESSAGES: 'dispute_messages',
  FIGHTER_PROFILES: 'fighter_profiles',
  SCHEDULED_FIGHTS: 'scheduled_fights',
  PROFILES: 'profiles',
};

export interface CreateDisputeRequest {
  fight_id?: string;
  scheduled_fight_id?: string;
  opponent_id?: string;
  reason: string;
  evidence_urls?: string[];
  fight_link?: string;
  dispute_category: 'cheating' | 'spamming' | 'exploits' | 'excessive_punches' | 'stamina_draining' | 'power_punches' | 'other';
  fighter1_name?: string;
  fighter2_name?: string;
}

export interface SendMessageRequest {
  dispute_id: string;
  message: string;
}

class DisputeService {
  // Get all disputes (for admin) or disputes for current fighter
  async getDisputes(fighterId?: string): Promise<Dispute[]> {
    try {
      // First, try a simpler query without foreign key joins to see if RLS is working
      let query = supabase
        .from(TABLES.DISPUTES)
        .select('*')
        .order('created_at', { ascending: false });

      if (fighterId) {
        // Get disputes where this fighter is the disputer or opponent
        // Use proper Supabase OR syntax
        query = query.or(`disputer_id.eq.${fighterId},opponent_id.eq.${fighterId}`);
      }

      const { data: basicData, error: basicError } = await query;

      if (basicError) {
        console.error('Error fetching disputes (basic query):', basicError);
        throw basicError;
      }

      if (!basicData || basicData.length === 0) {
        return [];
      }

      // If basic query worked, try to enrich with related data
      // Get fighter profile IDs from disputes (remove duplicates)
      const disputerIds = Array.from(new Set(basicData.map((d: any) => d.disputer_id).filter(Boolean)));
      const opponentIds = Array.from(new Set(basicData.map((d: any) => d.opponent_id).filter(Boolean)));
      const scheduledFightIds = Array.from(new Set(basicData.map((d: any) => d.fight_id).filter(Boolean)));

      // Fetch related fighter profiles
      const disputerProfiles: Record<string, any> = {};
      const opponentProfiles: Record<string, any> = {};
      const scheduledFights: Record<string, any> = {};

      if (disputerIds.length > 0) {
        const { data: disputers } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, user_id')
          .in('id', disputerIds);

        if (disputers) {
          disputers.forEach((fp: any) => {
            disputerProfiles[fp.id] = fp;
          });
        }
      }

      if (opponentIds.length > 0) {
        const { data: opponents } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, user_id')
          .in('id', opponentIds);

        if (opponents) {
          opponents.forEach((fp: any) => {
            opponentProfiles[fp.id] = fp;
          });
        }
      }

      if (scheduledFightIds.length > 0) {
        const { data: fights } = await supabase
          .from(TABLES.SCHEDULED_FIGHTS)
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .in('id', scheduledFightIds);

        if (fights) {
          fights.forEach((sf: any) => {
            scheduledFights[sf.id] = sf;
          });
        }
      }

      // Enrich the disputes with related data
      return basicData.map((dispute: any) => ({
        ...dispute,
        disputer: dispute.disputer_id ? disputerProfiles[dispute.disputer_id] : null,
        opponent: dispute.opponent_id ? opponentProfiles[dispute.opponent_id] : null,
        scheduled_fight: dispute.fight_id ? scheduledFights[dispute.fight_id] : null,
      })) as Dispute[];
    } catch (error: any) {
      console.error('Error in getDisputes:', error);
      // Provide more detailed error message
      const errorMessage = error?.message || JSON.stringify(error) || 'Unknown error';
      throw new Error(`Failed to load disputes: ${errorMessage}. Make sure RLS policies are properly configured.`);
    }
  }

  // Get a single dispute with all details
  async getDispute(disputeId: string, isAdmin: boolean = false): Promise<Dispute | null> {
    try {
      // First, fetch the basic dispute data
      const { data: basicData, error: basicError } = await supabase
        .from(TABLES.DISPUTES)
        .select('*')
        .eq('id', disputeId)
        .single();

      if (basicError) {
        console.error('Error fetching dispute (basic query):', basicError);
        throw basicError;
      }

      if (!basicData) {
        return null;
      }

      // If admin is viewing, update status to 'In Review' if it's 'Open'
      if (isAdmin && basicData.status === 'Open') {
        await supabase
          .from(TABLES.DISPUTES)
          .update({ status: 'In Review' })
          .eq('id', disputeId)
          .eq('status', 'Open');
        
        // Update basicData to reflect the status change
        basicData.status = 'In Review';
      }

      // Fetch related fighter profiles separately with full information (including physical info)
      let disputer = null;
      let opponent = null;
      let scheduledFight = null;

      if (basicData.disputer_id) {
        const { data: disputerData, error: disputerError } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, user_id, weight_class, tier, height_feet, height_inches, weight, reach, stance')
          .eq('id', basicData.disputer_id)
          .maybeSingle();
        
        if (disputerError) {
          console.error('Error fetching disputer profile:', disputerError);
        }
        disputer = disputerData || null;
      }

      if (basicData.opponent_id) {
        const { data: opponentData, error: opponentError } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, user_id, weight_class, tier, height_feet, height_inches, weight, reach, stance')
          .eq('id', basicData.opponent_id)
          .maybeSingle();
        
        if (opponentError) {
          console.error('Error fetching opponent profile:', opponentError);
        }
        opponent = opponentData || null;
      }

      if (basicData.fight_id) {
        const { data: fightData } = await supabase
          .from(TABLES.SCHEDULED_FIGHTS)
          .select('id, fighter1_id, fighter2_id, weight_class, scheduled_date, status')
          .eq('id', basicData.fight_id)
          .single();
        scheduledFight = fightData || null;
      }

      // Return enriched dispute data
      return {
        ...basicData,
        disputer,
        opponent,
        scheduled_fight: scheduledFight,
      };
    } catch (error: any) {
      console.error('Error in getDispute:', error);
      
      // Create a more descriptive error message
      const errorDetails = error.details ? ` Details: ${error.details}` : '';
      const errorHint = error.hint ? ` Hint: ${error.hint}` : '';
      const fullErrorMessage = `${error.message || 'Failed to fetch dispute'}${errorDetails}${errorHint}`;
      
      const dbError = new Error(fullErrorMessage);
      (dbError as any).code = error.code;
      (dbError as any).details = error.details;
      (dbError as any).hint = error.hint;
      throw dbError;
    }
  }

  // Create a new dispute
  async createDispute(request: CreateDisputeRequest, disputerId: string): Promise<Dispute> {
    // Validate all UUID inputs
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    // Validate disputerId
    if (!disputerId || !uuidRegex.test(disputerId)) {
      throw new Error(`Invalid disputer ID: "${disputerId}". Must be a valid UUID.`);
    }

    // Validate opponent_id if provided
    if (request.opponent_id && !uuidRegex.test(request.opponent_id)) {
      throw new Error(`Invalid opponent ID: "${request.opponent_id}". Must be a valid UUID.`);
    }

    // Map scheduled_fight_id to fight_id for the insert
    const fightId = request.scheduled_fight_id || request.fight_id || null;

    // Validate fight_id if provided
    if (fightId && !uuidRegex.test(fightId)) {
      console.error('Invalid fight ID:', fightId);
      console.error('Request object:', request);
      throw new Error(`Invalid fight ID: "${fightId}". Must be a valid UUID.`);
    }

    // Get fighter names if scheduled_fight_id is provided
    let fighter1Name: string | undefined;
    let fighter2Name: string | undefined;
    let opponentIdFromFight: string | undefined;

    if (fightId) {
      const { data: fight } = await supabase
        .from(TABLES.SCHEDULED_FIGHTS)
        .select('fighter1_id, fighter2_id')
        .eq('id', fightId)
        .single();

      if (fight) {
        const { data: fighter1 } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('name')
          .eq('id', fight.fighter1_id)
          .single();

        const { data: fighter2 } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('name')
          .eq('id', fight.fighter2_id)
          .single();

        fighter1Name = fighter1?.name;
        fighter2Name = fighter2?.name;

        // Determine opponent_id from the fight
        // The disputer is one of the fighters, so the opponent is the other one
        if (fight.fighter1_id === disputerId) {
          opponentIdFromFight = fight.fighter2_id;
        } else if (fight.fighter2_id === disputerId) {
          opponentIdFromFight = fight.fighter1_id;
        }
      }
    }

    // Use provided fighter names or the ones fetched from the fight
    const finalFighter1Name = request.fighter1_name || fighter1Name;
    const finalFighter2Name = request.fighter2_name || fighter2Name;

    // Determine opponent_id: use provided, or from fight, or try to find by name
    let finalOpponentId = request.opponent_id || opponentIdFromFight;
    
    // If still no opponent_id but we have fighter2_name, try to find by name
    if (!finalOpponentId && finalFighter2Name) {
      const { data: opponentProfile } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id')
        .eq('name', finalFighter2Name)
        .maybeSingle();
      
      if (opponentProfile) {
        finalOpponentId = opponentProfile.id;
      }
    }

    // Double-check all UUID values before inserting
    const insertData: any = {
      reason: request.reason,
      fighter1_name: finalFighter1Name || null,
      fighter2_name: finalFighter2Name || null,
      evidence_urls: request.evidence_urls || [],
      fight_link: request.fight_link || null,
      dispute_category: request.dispute_category,
      status: 'Open',
    };

    // Only add fight_id if it's a valid UUID
    if (fightId && uuidRegex.test(fightId)) {
      insertData.fight_id = fightId;
    } else if (fightId) {
      console.error('Rejecting invalid fight_id:', fightId);
      throw new Error(`Invalid fight_id: "${fightId}". Expected UUID but got: ${typeof fightId}`);
    }

    // Only add disputer_id if it's a valid UUID
    if (disputerId && uuidRegex.test(disputerId)) {
      insertData.disputer_id = disputerId;
    } else {
      console.error('Rejecting invalid disputer_id:', disputerId);
      throw new Error(`Invalid disputer_id: "${disputerId}". Expected UUID but got: ${typeof disputerId}`);
    }

    // Only add opponent_id if it's provided and is a valid UUID
    if (finalOpponentId) {
      if (uuidRegex.test(finalOpponentId)) {
        insertData.opponent_id = finalOpponentId;
      } else {
        console.error('Rejecting invalid opponent_id:', finalOpponentId);
        throw new Error(`Invalid opponent_id: "${finalOpponentId}". Expected UUID but got: ${typeof finalOpponentId}`);
      }
    }

    console.log('Inserting dispute with validated data:', {
      ...insertData,
      disputer_id: insertData.disputer_id?.substring(0, 8) + '...',
      opponent_id: insertData.opponent_id?.substring(0, 8) + '...',
      fight_id: insertData.fight_id?.substring(0, 8) + '...',
    });

    const { data: insertedData, error } = await supabase
      .from(TABLES.DISPUTES)
      .insert(insertData)
      .select('*')
      .single();

    if (error) {
      console.error('Database error details:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
      console.error('Data that was attempted to be inserted:', insertData);
      
      // Create a more descriptive error message
      const errorDetails = error.details ? ` Details: ${error.details}` : '';
      const errorHint = error.hint ? ` Hint: ${error.hint}` : '';
      const fullErrorMessage = `${error.message || 'Database error'}${errorDetails}${errorHint}`;
      
      // Throw a new Error with a descriptive message
      const dbError = new Error(fullErrorMessage);
      (dbError as any).code = error.code;
      (dbError as any).details = error.details;
      (dbError as any).hint = error.hint;
      throw dbError;
    }

    // Fetch related fighter profiles separately to avoid relationship issues
    let disputer = null;
    let opponent = null;

    if (insertedData.disputer_id) {
      const { data: disputerData } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, name, user_id')
        .eq('id', insertedData.disputer_id)
        .single();
      disputer = disputerData || null;
    }

    if (insertedData.opponent_id) {
      const { data: opponentData } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, name, user_id')
        .eq('id', insertedData.opponent_id)
        .single();
      opponent = opponentData || null;
    }

    // Return enriched dispute data
    const data = {
      ...insertedData,
      disputer,
      opponent,
    };

    // Update scheduled fight status to disputed if applicable
    if (request.scheduled_fight_id) {
      await supabase
        .from(TABLES.SCHEDULED_FIGHTS)
        .update({ status: 'Disputed' })
        .eq('id', request.scheduled_fight_id);
    }

    return data;
  }

  // Get messages for a dispute
  async getDisputeMessages(disputeId: string): Promise<DisputeMessage[]> {
    try {
      // First, fetch the basic message data
      const { data: messagesData, error: messagesError } = await supabase
        .from(TABLES.DISPUTE_MESSAGES)
        .select('*')
        .eq('dispute_id', disputeId)
        .order('created_at', { ascending: true });

      if (messagesError) {
        console.error('Error fetching dispute messages (basic query):', messagesError);
        throw messagesError;
      }

      if (!messagesData || messagesData.length === 0) {
        return [];
      }

      // Fetch sender profiles separately
      const senderIds = Array.from(new Set(messagesData.map((m: any) => m.sender_id).filter(Boolean)));
      const senderProfiles: Record<string, any> = {};

      if (senderIds.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, email, role')
          .in('id', senderIds);

        if (profiles) {
          profiles.forEach((p: any) => {
            senderProfiles[p.id] = p;
          });
        }
      }

      // Enrich messages with sender data
      return messagesData.map((message: any) => ({
        ...message,
        sender: senderProfiles[message.sender_id] || null,
      }));
    } catch (error: any) {
      console.error('Error in getDisputeMessages:', error);
      
      // Create a more descriptive error message
      const errorDetails = error.details ? ` Details: ${error.details}` : '';
      const errorHint = error.hint ? ` Hint: ${error.hint}` : '';
      const fullErrorMessage = `${error.message || 'Failed to fetch dispute messages'}${errorDetails}${errorHint}`;
      
      const dbError = new Error(fullErrorMessage);
      (dbError as any).code = error.code;
      (dbError as any).details = error.details;
      (dbError as any).hint = error.hint;
      throw dbError;
    }
  }

  // Send a message in a dispute
  async sendMessage(request: SendMessageRequest, senderId: string, senderType: 'fighter' | 'admin'): Promise<DisputeMessage> {
    try {
      // Insert the message
      const { data: insertedData, error: insertError } = await supabase
        .from(TABLES.DISPUTE_MESSAGES)
        .insert({
          dispute_id: request.dispute_id,
          sender_id: senderId,
          sender_type: senderType,
          message: request.message,
        })
        .select('*')
        .single();

      if (insertError) {
        console.error('Error inserting dispute message:', insertError);
        throw insertError;
      }

      if (!insertedData) {
        throw new Error('Message was not inserted');
      }

      // Fetch sender profile separately
      let sender = null;
      if (senderId) {
        const { data: senderData } = await supabase
          .from('profiles')
          .select('id, email, role')
          .eq('id', senderId)
          .single();
        sender = senderData || null;
      }

      // If sender is admin and dispute is open, update to Under Review
      if (senderType === 'admin') {
        await supabase
          .from(TABLES.DISPUTES)
          .update({ status: 'Under Review' })
          .eq('id', request.dispute_id)
          .eq('status', 'Open');
      }

      // Return enriched message data
      return {
        ...insertedData,
        sender,
      };
    } catch (error: any) {
      console.error('Error in sendMessage:', error);
      
      // Create a more descriptive error message
      const errorDetails = error.details ? ` Details: ${error.details}` : '';
      const errorHint = error.hint ? ` Hint: ${error.hint}` : '';
      const fullErrorMessage = `${error.message || 'Failed to send message'}${errorDetails}${errorHint}`;
      
      const dbError = new Error(fullErrorMessage);
      (dbError as any).code = error.code;
      (dbError as any).details = error.details;
      (dbError as any).hint = error.hint;
      throw dbError;
    }
  }

  // Send a message to both fighters in a dispute (admin only)
  async sendMessageToBothFighters(
    disputeId: string,
    messageToDisputer: string,
    messageToOpponent: string,
    adminId: string
  ): Promise<void> {
    try {
      // Get dispute to find fighter IDs
      const { data: dispute, error: disputeError } = await supabase
        .from(TABLES.DISPUTES)
        .select('disputer_id, opponent_id')
        .eq('id', disputeId)
        .single();

      if (disputeError || !dispute) {
        throw new Error('Dispute not found');
      }

      // Get user IDs for both fighters
      const disputerUserId = dispute.disputer_id 
        ? (await supabase.from(TABLES.FIGHTER_PROFILES).select('user_id').eq('id', dispute.disputer_id).single()).data?.user_id
        : null;
      
      const opponentUserId = dispute.opponent_id
        ? (await supabase.from(TABLES.FIGHTER_PROFILES).select('user_id').eq('id', dispute.opponent_id).single()).data?.user_id
        : null;

      // Update dispute with admin messages
      await supabase
        .from(TABLES.DISPUTES)
        .update({
          admin_message_to_disputer: messageToDisputer,
          admin_message_to_opponent: messageToOpponent,
        })
        .eq('id', disputeId);

      // Create messages in dispute_messages for both fighters
      const messagesToInsert: any[] = [];

      if (messageToDisputer && disputerUserId) {
        messagesToInsert.push({
          dispute_id: disputeId,
          sender_id: adminId,
          sender_type: 'admin',
          message: messageToDisputer,
        });
      }

      if (messageToOpponent && opponentUserId) {
        messagesToInsert.push({
          dispute_id: disputeId,
          sender_id: adminId,
          sender_type: 'admin',
          message: messageToOpponent,
        });
      }

      if (messagesToInsert.length > 0) {
        await supabase
          .from(TABLES.DISPUTE_MESSAGES)
          .insert(messagesToInsert);
      }
    } catch (error: any) {
      console.error('Error sending messages to both fighters:', error);
      throw error;
    }
  }

  // Resolve a dispute (admin only) with enhanced resolution types
  async resolveDispute(
    disputeId: string,
    resolutionType: 'warning' | 'give_win_to_submitter' | 'one_week_suspension' | 'two_week_suspension' | 'one_month_suspension' | 'banned_from_league' | 'dispute_invalid' | 'other',
    resolution: string,
    adminNotes?: string,
    messageToDisputer?: string,
    messageToOpponent?: string,
    adminId?: string
  ): Promise<void> {
    try {
      // Get dispute details
      const { data: dispute, error: disputeError } = await supabase
        .from(TABLES.DISPUTES)
        .select('disputer_id, opponent_id, fight_id, fighter2_name')
        .eq('id', disputeId)
        .single();

      if (disputeError || !dispute) {
        throw new Error('Dispute not found');
      }

      // If giving win to submitter, create fight records and update stats
      if (resolutionType === 'give_win_to_submitter') {
        if (!dispute.disputer_id) {
          throw new Error('Cannot give win: Missing disputer information');
        }

        // Try to get opponent_id if it's missing
        let opponentId = dispute.opponent_id;
        
        if (!opponentId) {
          // Try to get opponent_id from scheduled fight
          if (dispute.fight_id) {
            const { data: fight } = await supabase
              .from(TABLES.SCHEDULED_FIGHTS)
              .select('fighter1_id, fighter2_id')
              .eq('id', dispute.fight_id)
              .single();
            
            if (fight) {
              // Determine which fighter is the opponent (the one that's not the disputer)
              if (fight.fighter1_id === dispute.disputer_id) {
                opponentId = fight.fighter2_id;
              } else if (fight.fighter2_id === dispute.disputer_id) {
                opponentId = fight.fighter1_id;
              }
            }
          }
          
          // If still no opponent_id, try to find by fighter2_name
          if (!opponentId && dispute.fighter2_name) {
            const { data: opponentProfile } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('id')
              .eq('name', dispute.fighter2_name)
              .maybeSingle();
            
            if (opponentProfile) {
              opponentId = opponentProfile.id;
            }
          }
        }

        if (!opponentId) {
          throw new Error('Cannot give win: Missing opponent information. Please ensure the dispute has an opponent ID or fighter name.');
        }

        // Get fighter profiles
        const { data: disputerProfile } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, weight_class')
          .eq('id', dispute.disputer_id)
          .single();

        const { data: opponentProfile } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, weight_class')
          .eq('id', opponentId)
          .single();

        if (!disputerProfile || !opponentProfile) {
          throw new Error('Cannot give win: Fighter profiles not found');
        }

        // Get fight details if available
        let fightWeightClass = disputerProfile.weight_class || 'Lightweight';
        if (dispute.fight_id) {
          const { data: fight } = await supabase
            .from(TABLES.SCHEDULED_FIGHTS)
            .select('weight_class')
            .eq('id', dispute.fight_id)
            .single();
          if (fight?.weight_class) {
            fightWeightClass = fight.weight_class;
          }
        }

        // Create fight records using profile IDs (fighter_id references fighter_profiles(id))
        // Winner (disputer) - Win by Decision (default method)
        const winnerPoints = 5; // Base win points
        const { error: winnerRecordError } = await supabase
          .from('fight_records')
          .insert({
            fighter_id: dispute.disputer_id, // Use profile ID, not user_id
            opponent_name: opponentProfile.name,
            result: 'Win',
            method: 'UD', // Unanimous Decision - valid method value
            round: 0, // Required field
            date: new Date().toISOString().split('T')[0],
            weight_class: fightWeightClass,
            points_earned: winnerPoints,
            notes: 'Dispute resolution: Admin awarded win to submitter'
          });

        if (winnerRecordError) {
          console.error('Error creating winner fight record:', winnerRecordError);
          // Continue even if record creation fails
        }

        // Loser (opponent) - Loss
        const loserPoints = -3; // Loss points
        const { error: loserRecordError } = await supabase
          .from('fight_records')
          .insert({
            fighter_id: opponentId, // Use the resolved opponentId
            opponent_name: disputerProfile.name,
            result: 'Loss',
            method: 'UD', // Unanimous Decision - valid method value
            round: 0, // Required field
            date: new Date().toISOString().split('T')[0],
            weight_class: fightWeightClass,
            points_earned: loserPoints,
            notes: 'Dispute resolution: Admin awarded win to opponent'
          });

        if (loserRecordError) {
          console.error('Error creating loser fight record:', loserRecordError);
          // Continue even if record creation fails
        }

        // Update scheduled fight status if applicable
        if (dispute.fight_id) {
          await supabase
            .from(TABLES.SCHEDULED_FIGHTS)
            .update({ status: 'Completed' })
            .eq('id', dispute.fight_id);
        }
      }

      // Handle suspensions and bans
      if (resolutionType === 'one_week_suspension' || resolutionType === 'two_week_suspension' || resolutionType === 'one_month_suspension') {
        const suspensionDays = resolutionType === 'one_week_suspension' ? 7 
          : resolutionType === 'two_week_suspension' ? 14 
          : 30;

        // Apply suspension to opponent (the one being disputed against)
        // Try to get opponent_id if it's missing (same logic as above)
        let opponentId = dispute.opponent_id;
        
        if (!opponentId) {
          if (dispute.fight_id) {
            const { data: fight } = await supabase
              .from(TABLES.SCHEDULED_FIGHTS)
              .select('fighter1_id, fighter2_id')
              .eq('id', dispute.fight_id)
              .single();
            
            if (fight) {
              if (fight.fighter1_id === dispute.disputer_id) {
                opponentId = fight.fighter2_id;
              } else if (fight.fighter2_id === dispute.disputer_id) {
                opponentId = fight.fighter1_id;
              }
            }
          }
          
          if (!opponentId && dispute.fighter2_name) {
            const { data: opponentProfile } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('id')
              .eq('name', dispute.fighter2_name)
              .maybeSingle();
            
            if (opponentProfile) {
              opponentId = opponentProfile.id;
            }
          }
        }

        if (opponentId) {
          const { data: opponentProfile } = await supabase
            .from(TABLES.FIGHTER_PROFILES)
            .select('user_id')
            .eq('id', opponentId)
            .single();

          if (opponentProfile?.user_id) {
            const bannedUntil = new Date();
            bannedUntil.setDate(bannedUntil.getDate() + suspensionDays);

            await supabase
              .from('profiles')
              .update({
                banned_until: bannedUntil.toISOString(),
                banned_reason: `Dispute resolution: ${resolutionType.replace(/_/g, ' ')}`
              })
              .eq('id', opponentProfile.user_id);
          }
        }
      } else if (resolutionType === 'banned_from_league') {
        // Permanent ban
        // Try to get opponent_id if it's missing (same logic as above)
        let opponentId = dispute.opponent_id;
        
        if (!opponentId) {
          if (dispute.fight_id) {
            const { data: fight } = await supabase
              .from(TABLES.SCHEDULED_FIGHTS)
              .select('fighter1_id, fighter2_id')
              .eq('id', dispute.fight_id)
              .single();
            
            if (fight) {
              if (fight.fighter1_id === dispute.disputer_id) {
                opponentId = fight.fighter2_id;
              } else if (fight.fighter2_id === dispute.disputer_id) {
                opponentId = fight.fighter1_id;
              }
            }
          }
          
          if (!opponentId && dispute.fighter2_name) {
            const { data: opponentProfile } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('id')
              .eq('name', dispute.fighter2_name)
              .maybeSingle();
            
            if (opponentProfile) {
              opponentId = opponentProfile.id;
            }
          }
        }

        if (opponentId) {
          const { data: opponentProfile } = await supabase
            .from(TABLES.FIGHTER_PROFILES)
            .select('user_id')
            .eq('id', opponentId)
            .single();

          if (opponentProfile?.user_id) {
            await supabase
              .from('profiles')
              .update({
                banned_until: null, // null = permanent ban
                banned_reason: 'Dispute resolution: Banned from league'
              })
              .eq('id', opponentProfile.user_id);
          }
        }
      }

      // Send messages to both fighters if provided
      if (messageToDisputer || messageToOpponent) {
        if (adminId) {
          await this.sendMessageToBothFighters(
            disputeId,
            messageToDisputer || '',
            messageToOpponent || '',
            adminId
          );
        }
      }

      // Update dispute status to Resolved
      const { error } = await supabase
        .from(TABLES.DISPUTES)
        .update({
          status: 'Resolved',
          resolution_type: resolutionType,
          resolution,
          admin_notes: adminNotes,
          resolved_at: new Date().toISOString(),
        })
        .eq('id', disputeId);

      if (error) throw error;
    } catch (error: any) {
      console.error('Error resolving dispute:', error);
      throw error;
    }
  }

  // Delete all resolved disputes (admin only)
  async deleteAllResolvedDisputes(): Promise<number> {
    try {
      console.log('Starting deleteAllResolvedDisputes...');
      
      // First, get all resolved disputes to count them
      const { data: resolvedDisputes, error: fetchError } = await supabase
        .from(TABLES.DISPUTES)
        .select('id, status')
        .eq('status', 'Resolved');

      if (fetchError) {
        console.error('Error fetching resolved disputes:', fetchError);
        throw fetchError;
      }

      console.log(`Found ${resolvedDisputes?.length || 0} resolved disputes to delete`);
      console.log('Resolved disputes:', resolvedDisputes);

      if (!resolvedDisputes || resolvedDisputes.length === 0) {
        console.log('No resolved disputes found to delete');
        return 0;
      }

      const disputeIds = resolvedDisputes.map(d => d.id);
      
      // Delete all messages for these disputes first
      if (disputeIds.length > 0) {
        const { error: messagesError, count: messagesDeletedCount } = await supabase
          .from(TABLES.DISPUTE_MESSAGES)
          .delete()
          .in('dispute_id', disputeIds);

        if (messagesError) {
          console.error('Error deleting dispute messages:', messagesError);
          // Don't throw - continue with deleting disputes even if messages fail
          console.warn('Warning: Some messages may not have been deleted');
        } else {
          console.log(`Deleted messages for ${disputeIds.length} disputes`);
        }
      }

      // Delete all resolved disputes
      // Note: Supabase delete with select() may not return all deleted rows due to RLS
      // So we'll use the count from the initial query
      const { error: deleteError } = await supabase
        .from(TABLES.DISPUTES)
        .delete()
        .in('id', disputeIds);

      if (deleteError) {
        console.error('Error deleting resolved disputes:', deleteError);
        throw deleteError;
      }

      // Verify deletion by checking how many remain
      const { data: remainingDisputes, error: verifyError } = await supabase
        .from(TABLES.DISPUTES)
        .select('id', { count: 'exact', head: true })
        .in('id', disputeIds);

      if (verifyError) {
        console.warn('Could not verify deletion:', verifyError);
      }

      const deletedCount = resolvedDisputes.length;
      console.log(`Successfully deleted ${deletedCount} resolved disputes`);
      
      return deletedCount;
    } catch (error: any) {
      console.error('Error in deleteAllResolvedDisputes:', error);
      throw error;
    }
  }

  // Submit a fight record (creates a pending submission)
  async submitFightRecord(submission: Omit<FightRecordSubmission, 'id' | 'status' | 'created_at' | 'updated_at'>): Promise<FightRecordSubmission> {
    const { data, error } = await supabase
      .from('fight_record_submissions')
      .insert({
        scheduled_fight_id: submission.scheduled_fight_id,
        fighter_id: submission.fighter_id,
        opponent_id: submission.opponent_id,
        result: submission.result,
        method: submission.method,
        round: submission.round || null,
        date: submission.date,
        weight_class: submission.weight_class,
        proof_url: submission.proof_url || null,
        notes: submission.notes || null,
        status: 'Pending',
      })
      .select(`
        *,
        fighter:fighter_profiles!fight_record_submissions_fighter_id_fkey(
          id,
          name,
          user_id
        ),
        opponent:fighter_profiles!fight_record_submissions_opponent_id_fkey(
          id,
          name,
          user_id
        ),
        scheduled_fight:scheduled_fights(
          id,
          fighter1_id,
          fighter2_id,
          weight_class,
          scheduled_date,
          status
        )
      `)
      .single();

    if (error) throw error;
    return data;
  }

  // Get pending fight record submissions for a fighter
  async getFightRecordSubmissions(fighterId?: string, scheduledFightId?: string): Promise<FightRecordSubmission[]> {
    let query = supabase
      .from('fight_record_submissions')
      .select(`
        *,
        fighter:fighter_profiles!fight_record_submissions_fighter_id_fkey(
          id,
          name,
          user_id
        ),
        opponent:fighter_profiles!fight_record_submissions_opponent_id_fkey(
          id,
          name,
          user_id
        ),
        scheduled_fight:scheduled_fights(
          id,
          fighter1_id,
          fighter2_id,
          weight_class,
          scheduled_date,
          status
        )
      `)
      .order('created_at', { ascending: false });

    if (fighterId) {
      query = query.or(`fighter_id.eq.${fighterId},opponent_id.eq.${fighterId}`);
    }

    if (scheduledFightId) {
      query = query.eq('scheduled_fight_id', scheduledFightId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  }

  // Update a fight record submission (fighter can edit before confirmation)
  async updateFightRecordSubmission(
    submissionId: string,
    updates: Partial<Omit<FightRecordSubmission, 'id' | 'status' | 'created_at' | 'updated_at'>>
  ): Promise<FightRecordSubmission> {
    const { data, error } = await supabase
      .from('fight_record_submissions')
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq('id', submissionId)
      .select(`
        *,
        fighter:fighter_profiles!fight_record_submissions_fighter_id_fkey(
          id,
          name,
          user_id
        ),
        opponent:fighter_profiles!fight_record_submissions_opponent_id_fkey(
          id,
          name,
          user_id
        )
      `)
      .single();

    if (error) throw error;
    return data;
  }
}

export const disputeService = new DisputeService();

