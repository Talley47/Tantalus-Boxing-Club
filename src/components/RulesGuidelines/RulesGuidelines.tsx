import React, { useState } from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Divider,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Alert,
} from '@mui/material';
import {
  ExpandMore,
  Gavel,
  EmojiEvents,
  TrendingUp,
  People,
  SportsMma,
  Schedule,
  FitnessCenter,
  Sports,
  ArrowUpward,
  ArrowDownward,
  CheckCircle,
  Cancel,
} from '@mui/icons-material';

const RulesGuidelines: React.FC = () => {
  // Rules/Guidelines component for Creative Fighter League
  const [expanded, setExpanded] = useState<string | false>('introduction');

  // Ensure component is loaded in production
  React.useEffect(() => {
    // Log component mount for debugging
    console.log('RulesGuidelines component mounted', { 
      env: process.env.NODE_ENV,
      timestamp: new Date().toISOString()
    });
  }, []);

  const handleChange = (panel: string) => (event: React.SyntheticEvent, isExpanded: boolean) => {
    setExpanded(isExpanded ? panel : false);
  };

  // Force component to be included in production build
  if (typeof window !== 'undefined') {
    // Ensure component is loaded
    (window as any).__RULES_GUIDELINES_LOADED__ = true;
  }

  // Early return test - if this doesn't show, component isn't rendering
  try {
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        {/* Header */}
        <Paper elevation={3} sx={{ p: 4, mb: 4, background: 'linear-gradient(135deg, #d32f2f 0%, #9a0007 100%)' }}>
        <Box display="flex" alignItems="center" gap={2} mb={2}>
          <Gavel sx={{ fontSize: 40, color: 'white' }} />
          <Box>
            <Typography variant="h3" component="h1" color="white" fontWeight="bold">
              Tantalus Boxing Club – Creative Fighter League
            </Typography>
            <Typography variant="h6" color="rgba(255,255,255,0.9)" sx={{ mt: 1 }}>
              Official Rules & Guidelines (v1.0)
            </Typography>
          </Box>
        </Box>
        <Box display="flex" gap={3} flexWrap="wrap" mt={2}>
          <Chip 
            label={`Last Updated: November 16, 2025`} 
            sx={{ bgcolor: 'rgba(255,255,255,0.2)', color: 'white' }} 
          />
          <Chip 
            label="Governing Body: Tantalus Boxing Club (TBC)" 
            sx={{ bgcolor: 'rgba(255,255,255,0.2)', color: 'white' }} 
          />
          <Chip 
            label="League Name: Creative Fighter League (CFL)" 
            sx={{ bgcolor: 'rgba(255,255,255,0.2)', color: 'white' }} 
          />
        </Box>
      </Paper>

      {/* Table of Contents */}
      <Paper elevation={2} sx={{ p: 3, mb: 4 }}>
        <Typography variant="h5" gutterBottom fontWeight="bold">
          Table of Contents
        </Typography>
        <List dense>
          {[
            { id: 'introduction', text: 'Introduction', icon: <People /> },
            { id: 'tier-system', text: 'Tier System', icon: <TrendingUp /> },
            { id: 'points-system', text: 'Points System', icon: <EmojiEvents /> },
            { id: 'rankings-system', text: 'Rankings System', icon: <TrendingUp /> },
            { id: 'matchmaking-rules', text: 'Matchmaking Rules', icon: <SportsMma /> },
            { id: 'tournament-rules', text: 'Tournament Rules', icon: <Sports /> },
            { id: 'training-camp-system', text: 'Training Camp System', icon: <FitnessCenter /> },
            { id: 'callout-rematch-system', text: 'Callout/Rematch System', icon: <SportsMma /> },
            { id: 'fight-scheduling-rules', text: 'Fight Scheduling Rules', icon: <Schedule /> },
            { id: 'demotion-promotion-system', text: 'Demotion and Promotion System', icon: <ArrowUpward /> },
            { id: 'simulation-standard', text: 'Simulation Virtual Boxing Standard (Undisputed)', icon: <Gavel /> },
            { id: 'code-of-conduct', text: 'Code of Conduct', icon: <Gavel /> },
            { id: 'general-guidelines', text: 'General Guidelines', icon: <People /> },
            { id: 'quick-reference', text: 'Appendix: Quick Reference', icon: <CheckCircle /> },
          ].map((item) => (
            <ListItem 
              key={item.id}
              disablePadding
              sx={{ mb: 0.5 }}
            >
              <ListItemButton
                onClick={() => {
                  setExpanded(item.id);
                  document.getElementById(item.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }}
                sx={{ borderRadius: 1 }}
              >
                <ListItemText 
                  primary={item.text}
                  primaryTypographyProps={{ variant: 'body2' }}
                />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </Paper>

      {/* Introduction */}
      <Accordion expanded={expanded === 'introduction'} onChange={handleChange('introduction')} id="introduction">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <People color="primary" />
            <Typography variant="h5" fontWeight="bold">Introduction</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            Welcome to the <strong>Tantalus Boxing Club – Creative Fighter League (TBC‑CFL)</strong>: a competitive Undisputed league where created fighters advance through tiers, compete in tournaments, and build their legacy through skill, discipline, and fairness.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 3, mb: 2 }}>Core Principles</Typography>
          <List>
            <ListItem>
              <ListItemText 
                primary="Fair Competition"
                secondary="Matches are driven by skill, tier, and ranking integrity."
              />
            </ListItem>
            <ListItem>
              <ListItemText 
                primary="Progressive Advancement"
                secondary="Fighters rise from Amateur to Elite through performance."
              />
            </ListItem>
            <ListItem>
              <ListItemText 
                primary="Respect & Sportsmanship"
                secondary="Conduct yourself as a professional inside and outside the ring."
              />
            </ListItem>
            <ListItem>
              <ListItemText 
                primary="Transparency"
                secondary="Rankings, points, and match outcomes are visible to the community."
              />
            </ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Tier System */}
      <Accordion expanded={expanded === 'tier-system'} onChange={handleChange('tier-system')} id="tier-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <TrendingUp color="primary" />
            <Typography variant="h5" fontWeight="bold">Tier System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            All fighters start in <strong>Amateur</strong> and progress by earning points.
          </Typography>
          <TableContainer component={Paper} sx={{ mt: 2, mb: 2 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell><strong>Tier</strong></TableCell>
                  <TableCell><strong>Points Range</strong></TableCell>
                  <TableCell><strong>Benefits</strong></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                <TableRow>
                  <TableCell><strong>Amateur</strong></TableCell>
                  <TableCell>0–29</TableCell>
                  <TableCell>Basic training access, local events</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Semi‑Pro</strong></TableCell>
                  <TableCell>30–69</TableCell>
                  <TableCell>Advanced training, regional events, basic analytics</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Pro</strong></TableCell>
                  <TableCell>70–139</TableCell>
                  <TableCell>Professional training, national events, full analytics, sponsorship opportunities</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Contender</strong></TableCell>
                  <TableCell>140–279</TableCell>
                  <TableCell>Elite training, championship events, advanced analytics, media coverage, title shots</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Elite</strong></TableCell>
                  <TableCell>280+</TableCell>
                  <TableCell>World‑class training, global events, premium analytics, live streaming, interviews, championship belts</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </TableContainer>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Tier Advancement</Typography>
          <List>
            <ListItem>
              <ListItemText primary="Automatic Promotion when you reach the next tier's minimum points." />
            </ListItem>
            <ListItem>
              <ListItemText primary="Tier Benefits unlock immediately upon promotion." />
            </ListItem>
            <ListItem>
              <ListItemText primary="Tier Lock: You cannot be demoted below your current tier due to points alone (see Demotion System)." />
            </ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Points System */}
      <Accordion expanded={expanded === 'points-system'} onChange={handleChange('points-system')} id="points-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <EmojiEvents color="primary" />
            <Typography variant="h5" fontWeight="bold">Points System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            Every official fight affects your total.
          </Typography>
          <TableContainer component={Paper} sx={{ mt: 2, mb: 2 }}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell><strong>Result</strong></TableCell>
                  <TableCell><strong>Points</strong></TableCell>
                  <TableCell><strong>Notes</strong></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                <TableRow>
                  <TableCell><strong>Win</strong></TableCell>
                  <TableCell>+5</TableCell>
                  <TableCell>Base points for victory</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Win by KO/TKO</strong></TableCell>
                  <TableCell>+8</TableCell>
                  <TableCell>+5 base +3 KO bonus</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Loss</strong></TableCell>
                  <TableCell>−3</TableCell>
                  <TableCell>Deduction for defeat</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Draw</strong></TableCell>
                  <TableCell>0</TableCell>
                  <TableCell>No change</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </TableContainer>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Notes</Typography>
          <List>
            <ListItem>
              <ListItemText primary="Both fighters' records are updated after each bout." />
            </ListItem>
            <ListItem>
              <ListItemText primary="KO/TKO bonus applies only to the winner." />
            </ListItem>
            <ListItem>
              <ListItemText primary="Points are calculated automatically upon verified result submission." />
            </ListItem>
            <ListItem>
              <ListItemText primary="Full point history appears in each fighter's record." />
            </ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Rankings System */}
      <Accordion expanded={expanded === 'rankings-system'} onChange={handleChange('rankings-system')} id="rankings-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <TrendingUp color="primary" />
            <Typography variant="h5" fontWeight="bold">Rankings System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            Rank determines position within weight class, tier, and overall league.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>Ranking Factors (priority order):</Typography>
          <List>
            <ListItem><ListItemText primary="1. Total Points" /></ListItem>
            <ListItem><ListItemText primary="2. Head‑to‑Head Record" /></ListItem>
            <ListItem><ListItemText primary="3. KO%" /></ListItem>
            <ListItem><ListItemText primary="4. Strength of Opponent (average points of opponents)" /></ListItem>
            <ListItem><ListItemText primary="5. Recent Form (last 5 fights)" /></ListItem>
            <ListItem><ListItemText primary="6. Win %" /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Ranking Types:</Typography>
          <List>
            <ListItem><ListItemText primary="Weight Class Rankings (division specific)" /></ListItem>
            <ListItem><ListItemText primary="Overall Rankings (cross‑division)" /></ListItem>
            <ListItem><ListItemText primary="Tier Rankings (within your current tier)" /></ListItem>
          </List>
          <Alert severity="info" sx={{ mt: 2 }}>
            Rankings update after each verified result and are reconciled daily.
          </Alert>
        </AccordionDetails>
      </Accordion>

      {/* Matchmaking Rules */}
      <Accordion expanded={expanded === 'matchmaking-rules'} onChange={handleChange('matchmaking-rules')} id="matchmaking-rules">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <SportsMma color="primary" />
            <Typography variant="h5" fontWeight="bold">Matchmaking Rules</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            The <strong>Smart Matchmaking</strong> system ensures competitive parity.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Mandatory Fights (Auto‑Matched)</Typography>
          <Typography variant="body2" paragraph sx={{ mb: 2 }}>
            <strong>All must be true:</strong>
          </Typography>
          <List>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="Same Weight Class" />
            </ListItem>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="Same Tier" />
            </ListItem>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="Rank within 3 positions" />
            </ListItem>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="Points within 30 points" />
            </ListItem>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="Timezones within 4 hours" />
            </ListItem>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="No Recent Opponents (avoids last 5)" />
            </ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Process:</strong> System generates pairing and notifies both fighters. Mandatory fight date is set <strong>one week</strong> from assignment. Bout must be completed within <strong>7 days</strong> of scheduling.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Manual Matchmaking (Weekly Mandatory Opponent Selection)</Typography>
          <List>
            <ListItem><ListItemText primary="Choose a suggested opponent who meets the same criteria." /></ListItem>
            <ListItem><ListItemText primary="Opponent must accept before scheduling." /></ListItem>
            <ListItem><ListItemText primary="You cannot accept your own request." /></ListItem>
            <ListItem><ListItemText primary="Once both accept, the fight is scheduled and binding." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Fair Match Guarantees</Typography>
          <List>
            <ListItem><ListItemText primary="Points Gap Protection: If difference > 50 points, explicit consent from both fighters required." /></ListItem>
            <ListItem><ListItemText primary="Tier Protection: Matches occur within the same tier." /></ListItem>
            <ListItem><ListItemText primary="Rank Protection: Ranks must be within 3 positions." /></ListItem>
            <ListItem><ListItemText primary="Timezone Compatibility: Required for scheduling." /></ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Tournament Rules */}
      <Accordion expanded={expanded === 'tournament-rules'} onChange={handleChange('tournament-rules')} id="tournament-rules">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <Sports color="primary" />
            <Typography variant="h5" fontWeight="bold">Tournament Rules</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="h6" gutterBottom>Eligibility (all required):</Typography>
          <List>
            <ListItem><ListItemText primary="1. Correct weight class (or approved adjacent class)." /></ListItem>
            <ListItem><ListItemText primary="2. Meet tournament minimum tier." /></ListItem>
            <ListItem><ListItemText primary="3. Meet minimum points (if listed)." /></ListItem>
            <ListItem><ListItemText primary="4. Meet minimum rank (if listed)." /></ListItem>
            <ListItem><ListItemText primary="5. Register before the posted deadline." /></ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Formats:</strong> Single Elimination, Double Elimination, Group Stage → Knockouts, Swiss, Round Robin.
          </Typography>
          <Typography variant="body2" paragraph>
            <strong>Rules:</strong> Check‑in is required; no‑shows are eliminated; seeding uses current rankings; prize pools may be offered; entry fees may apply.
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Training Camp System */}
      <Accordion expanded={expanded === 'training-camp-system'} onChange={handleChange('training-camp-system')} id="training-camp-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <FitnessCenter color="primary" />
            <Typography variant="h5" fontWeight="bold">Training Camp System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            Practice without record impact.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>Invites:</Typography>
          <List>
            <ListItem><ListItemText primary="Invite any fighter except scheduled or past opponents." /></ListItem>
            <ListItem><ListItemText primary="Up to 3 active sparring partners." /></ListItem>
            <ListItem><ListItemText primary="Camps last 72 hours from acceptance." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Restrictions:</Typography>
          <List>
            <ListItem><ListItemText primary="Cannot start a camp within 3 days of a scheduled fight." /></ListItem>
            <ListItem><ListItemText primary="Both fighters must accept." /></ListItem>
            <ListItem><ListItemText primary="Camps expire after 72 hours." /></ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Benefits:</strong> Skill work, strategy testing, relationship building. No points are at stake.
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Callout/Rematch System */}
      <Accordion expanded={expanded === 'callout-rematch-system'} onChange={handleChange('callout-rematch-system')} id="callout-rematch-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <SportsMma color="primary" />
            <Typography variant="h5" fontWeight="bold">Callout/Rematch System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            Request a rematch with a fighter you've previously faced.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>Eligibility:</Typography>
          <List>
            <ListItem><ListItemText primary="Prior opponent only." /></ListItem>
            <ListItem><ListItemText primary="Both fighters must have availability (no conflicts)." /></ListItem>
            <ListItem><ListItemText primary="Must be a fair match (same tier, similar ranking)." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Process:</Typography>
          <List>
            <ListItem><ListItemText primary="1. Select prior opponent from history, send callout with optional message." /></ListItem>
            <ListItem><ListItemText primary="2. Target receives notification." /></ListItem>
            <ListItem><ListItemText primary="3. On acceptance, fight is scheduled as a Scheduled Rematch." /></ListItem>
            <ListItem><ListItemText primary="4. All standard scheduled‑fight rules apply." /></ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Fair Match Requirements:</strong> Same weight, same tier (or adjacent with consent), rankings in reasonable range, compatible timezones.
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Fight Scheduling Rules */}
      <Accordion expanded={expanded === 'fight-scheduling-rules'} onChange={handleChange('fight-scheduling-rules')} id="fight-scheduling-rules">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <Schedule color="primary" />
            <Typography variant="h5" fontWeight="bold">Fight Scheduling Rules</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="h6" gutterBottom>Mandatory Fights:</Typography>
          <List>
            <ListItem><ListItemText primary="Scheduled within 1 week of assignment and completed within 7 days." /></ListItem>
            <ListItem><ListItemText primary="Agree on date/time/platform; coordinate timezones." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Scheduled Fights (non‑mandatory):</Typography>
          <List>
            <ListItem><ListItemText primary="May be set up to 4 weeks in advance." /></ListItem>
            <ListItem><ListItemText primary="Must include: date/time (with timezone), platform (PC/Xbox/PlayStation), connection notes, and any house rules." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>After the Fight:</Typography>
          <List>
            <ListItem><ListItemText primary="1. Both fighters submit results." /></ListItem>
            <ListItem><ListItemText primary="2. Results must match." /></ListItem>
            <ListItem><ListItemText primary="3. If not, a dispute is opened." /></ListItem>
            <ListItem><ListItemText primary="4. Points are applied automatically after verification." /></ListItem>
            <ListItem><ListItemText primary="5. Records update and rankings recalc." /></ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Disputes:</strong> Must be filed within 48 hours of the scheduled fight time. Admins review evidence and decide.
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Demotion and Promotion System */}
      <Accordion expanded={expanded === 'demotion-promotion-system'} onChange={handleChange('demotion-promotion-system')} id="demotion-promotion-system">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <ArrowUpward color="primary" />
            <Typography variant="h5" fontWeight="bold">Demotion and Promotion System</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            <strong>Automatic Promotion:</strong> Points‑based; triggered immediately on reaching the next tier's threshold.
          </Typography>
          <Typography variant="body1" paragraph>
            <strong>No Manual Promotion:</strong> Promotions are automatic.
          </Typography>
          <Typography variant="body1" paragraph>
            <strong>Demotion Protection:</strong> You cannot drop a tier due to points loss alone.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Demotion (Consecutive Losses):</Typography>
          <List>
            <ListItem>
              <Cancel color="error" sx={{ mr: 1 }} />
              <ListItemText primary="4 straight losses → demoted one tier." />
            </ListItem>
            <ListItem><ListItemText primary="Demotion is immediate after the 4th loss." /></ListItem>
            <ListItem><ListItemText primary="You keep your points but move to the lower tier." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Promotion After Demotion:</Typography>
          <List>
            <ListItem>
              <CheckCircle color="success" sx={{ mr: 1 }} />
              <ListItemText primary="5 straight wins → promoted back according to points; you cannot exceed the tier your points warrant." />
            </ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Simulation Standard */}
      <Accordion expanded={expanded === 'simulation-standard'} onChange={handleChange('simulation-standard')} id="simulation-standard">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <Gavel color="primary" />
            <Typography variant="h5" fontWeight="bold">Simulation Virtual Boxing Standard (Undisputed)</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="body1" paragraph>
            This section defines <strong>simulation</strong> for Undisputed matches in TBC‑CFL and integrates directly with league operations.
          </Typography>
          
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>1) Philosophy & Definition</Typography>
          <Typography variant="body2" paragraph>
            Sim means boxing to real‑fight principles—not exploiting game systems.
          </Typography>
          <List>
            <ListItem><ListItemText primary="Pace realistically and manage stamina; build behind the jab." /></ListItem>
            <ListItem><ListItemText primary="Use varied offense/defense; clean punching over volume spam." /></ListItem>
            <ListItem><ListItemText primary="Show ring generalship; do not 'run' to avoid exchanges." /></ListItem>
            <ListItem><ListItemText primary="Accept realistic outcomes (cuts, attrition, momentum shifts)." /></ListItem>
          </List>
          <Alert severity="warning" sx={{ mt: 2 }}>
            <strong>Non‑Sim Examples:</strong> Punch spam (especially body spam), macro/turbo use, perpetual backpedal with no engagement, repeated push/clinch spam to stall, or any exploit/bug use.
          </Alert>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>2) Match Formats & Setup (Host Settings)</Typography>
          <List>
            <ListItem><ListItemText primary="Bout Types: Amateur 4–6 | Exhibition 6–8 | Contender/Main 8–10 | Championship 10–12." /></ListItem>
            <ListItem><ListItemText primary="Game Type: Simulation (or closest online equivalent)" /></ListItem>
            <ListItem><ListItemText primary="Round Length: 3:00 (Relative Time = 1.00)" /></ListItem>
            <ListItem><ListItemText primary="Knockdown Limit: 3 (3 KD Rule)" /></ListItem>
            <ListItem><ListItemText primary="Saved by the Bell: Off" /></ListItem>
            <ListItem><ListItemText primary="Referee Leniency: 3.0" /></ListItem>
            <ListItem><ListItemText primary="Maximum Penalties: 2.0" /></ListItem>
            <ListItem><ListItemText primary="Cuts/Injuries: On" /></ListItem>
            <ListItem><ListItemText primary="Fouls: On" /></ListItem>
            <ListItem><ListItemText primary="Judging: 10‑Point Must" /></ListItem>
            <ListItem><ListItemText primary="HUD/Camera: Minimal HUD preferred; default camera only unless pre‑agreed" /></ListItem>
            <ListItem><ListItemText primary="Connectivity: Stable connection required; ref/commissioner may order restart/reschedule for latency or desync." /></ListItem>
          </List>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>3) Weight Classes & Fighter Selection</Typography>
          <List>
            <ListItem><ListItemText primary="Sanctioned bouts must be same weight class; catchweights require mutual consent and pre‑announcement." /></ListItem>
            <ListItem><ListItemText primary="Mirror matches discouraged for title fights; coin‑toss/draft order resolves conflicts." /></ListItem>
            <ListItem><ListItemText primary="Fighters disclose controller type; macros/turbos are banned." /></ListItem>
          </List>

          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Created Fighter (CAF) Policy (League Caps)</Typography>
          <Typography variant="body2" paragraph>
            To keep CAFs fair and believable:
          </Typography>
          <List>
            <ListItem><ListItemText primary="Attribute Budget Cap: League‑set total budget per CAF." /></ListItem>
            <ListItem><ListItemText primary="Hard Caps: Max 2 attributes > 90; no stat > 92." /></ListItem>
            <ListItem><ListItemText primary="Body Metrics: Height/reach must be plausible for the weight class; no extreme body types to evade hitboxes." /></ListItem>
            <ListItem><ListItemText primary="Cosmetics: No distracting/glitch‑triggering gear." /></ListItem>
            <ListItem><ListItemText primary="Audit: Submit CAF screenshots for approval before first sanctioned bout." /></ListItem>
          </List>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>4) Simulation Standards (In‑Ring Conduct)</Typography>
          <List>
            <ListItem><ListItemText primary="Pacing & Output: Aim ~35–70 punches/round on average; sustained >90/rd over multiple rounds is a spam flag." /></ListItem>
            <ListItem><ListItemText primary="Shot Selection: At least 20% jabs across the fight; mix straights/hooks/uppercuts; avoid repeating the same power shot >3 times consecutively." /></ListItem>
            <ListItem><ListItemText primary="Targeting Balance: No more than 70% to head or body over the whole bout without clear tactical reason." /></ListItem>
            <ListItem><ListItemText primary="Engagement: Lateral movement ok; repeatedly sprinting corner‑to‑corner without throwing (>15s, twice in a round) is running → warning." /></ListItem>
            <ListItem><ListItemText primary="Clinch/Push: Use to recover or reset only; >5 neutral clinches/round (while not hurt) or push‑spam → penalties." /></ListItem>
            <ListItem><ListItemText primary="Power Use: 2–4 shot combos typical; power‑modifier reserved for set‑ups/openings." /></ListItem>
            <ListItem><ListItemText primary="Sportsmanship: No taunt spam, glove‑touch fakes into power shots, or post‑bell punches." /></ListItem>
          </List>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>5) Prohibited Tactics & Exploits</Typography>
          <List>
            <ListItem><ListItemText primary="Repetitive same‑punch spam (e.g., hook‑hook‑hook‑hook), nonstop body jab/uppercut spam, jab‑dash loops." /></ListItem>
            <ListItem><ListItemText primary="Stalling through non‑engagement, corner‑escape loops, clinch/push spam." /></ListItem>
            <ListItem><ListItemText primary="Any exploit/bug or disconnect/no‑loss trick; collision/hitbox abuse." /></ListItem>
            <ListItem><ListItemText primary="Macros/turbos/scripts and rapid‑fire hardware/software." /></ListItem>
          </List>
          <Alert severity="error" sx={{ mt: 2 }}>
            <strong>Penalty Ladder:</strong> Verbal Warning → Official Warning (1‑point deduction) → DQ → Suspension
          </Alert>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>6) Judging & Scoring</Typography>
          <List>
            <ListItem><ListItemText primary="Three judges; 10‑Point Must each round." /></ListItem>
            <ListItem><ListItemText primary="Criteria: Clean punching, effective aggression, ring generalship, defense." /></ListItem>
            <ListItem><ListItemText primary="Knockdowns and point deductions applied per rules." /></ListItem>
            <ListItem><ListItemText primary="Commission may review/overturn if the in‑game decision contradicts sim standards." /></ListItem>
          </List>
          <Typography variant="body2" paragraph sx={{ mt: 2 }}>
            <strong>Post‑Fight Stats (recommended):</strong> Submit screenshots (total/jab/power thrown/landed, head/body split, stamina) with cards for audits.
          </Typography>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>7) Refereeing & Administration</Typography>
          <List>
            <ListItem><ListItemText primary="Pre‑fight: Ref validates settings, rounds, division, and connection quality." /></ListItem>
            <ListItem><ListItemText primary="During fight: Issue warnings for non‑sim conduct; one pause per fighter to resolve latency/input issues." /></ListItem>
            <ListItem><ListItemText primary="Medical: Cuts/swelling are part of sim; stop for TKO when warranted." /></ListItem>
            <ListItem><ListItemText primary="Cards: Judges keep round‑by‑round cards; ref collects and submits." /></ListItem>
          </List>

          <Typography variant="h6" gutterBottom sx={{ mt: 4 }}>8) Integrity, Reporting & Appeals</Typography>
          <List>
            <ListItem><ListItemText primary="Save clips of key moments (KDs, fouls)." /></ListItem>
            <ListItem><ListItemText primary="Protests: Filed within 24 hours with timestamps/stats." /></ListItem>
            <ListItem><ListItemText primary="Appeals Panel: Commissioner + two neutral seniors; majority decision final." /></ListItem>
            <ListItem><ListItemText primary="Possible sanctions: point deductions, No Contest, suspensions, rank forfeits." /></ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Code of Conduct */}
      <Accordion expanded={expanded === 'code-of-conduct'} onChange={handleChange('code-of-conduct')} id="code-of-conduct">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <Gavel color="primary" />
            <Typography variant="h5" fontWeight="bold">Code of Conduct</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="h6" gutterBottom>Respect & Sportsmanship</Typography>
          <List>
            <ListItem><ListItemText primary="Respect all members regardless of tier/rank." /></ListItem>
            <ListItem><ListItemText primary="No cheating, exploiting, or unsportsmanlike conduct." /></ListItem>
            <ListItem><ListItemText primary="Submit accurate results." /></ListItem>
            <ListItem><ListItemText primary="Respond promptly to match requests and admin messages." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Prohibited</Typography>
          <List>
            <ListItem><ListItemText primary="Harassment, discriminatory language, false reporting, ghosting scheduled fights, exploiting bugs/loopholes." /></ListItem>
          </List>
          <Alert severity="warning" sx={{ mt: 2 }}>
            <strong>Consequences:</strong> Warnings, point deductions, temporary suspensions, or permanent bans for severe violations.
          </Alert>
        </AccordionDetails>
      </Accordion>

      {/* General Guidelines */}
      <Accordion expanded={expanded === 'general-guidelines'} onChange={handleChange('general-guidelines')} id="general-guidelines">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <People color="primary" />
            <Typography variant="h5" fontWeight="bold">General Guidelines</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <Typography variant="h6" gutterBottom>Getting Started:</Typography>
          <List>
            <ListItem><ListItemText primary="1. Complete your fighter profile (stats, trainer, gym, platform, timezone)." /></ListItem>
            <ListItem><ListItemText primary="2. Choose your weight class (changes are limited)." /></ListItem>
            <ListItem><ListItemText primary="3. Begin with mandatory fights or find opponents via matchmaking." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Best Practices:</Typography>
          <List>
            <ListItem><ListItemText primary="New Fighters: Focus on learning in Amateur; fill your profile; enter eligible tournaments; build steadily." /></ListItem>
            <ListItem><ListItemText primary="Experienced Fighters: Maintain rank via consistent activity; use camps; mentor newcomers." /></ListItem>
            <ListItem><ListItemText primary="Everyone: Keep profiles up to date; respond quickly; report results accurately; follow announcements." /></ListItem>
          </List>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Tips for Success:</Typography>
          <Typography variant="body2" paragraph>
            Consistency, fair matchups, tournament participation, training camps, positive community engagement.
          </Typography>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>Support:</Typography>
          <List>
            <ListItem><ListItemText primary="Read this guide first." /></ListItem>
            <ListItem><ListItemText primary="Contact admins for disputes or technical issues." /></ListItem>
            <ListItem><ListItemText primary="Watch the News feed for updates." /></ListItem>
          </List>
        </AccordionDetails>
      </Accordion>

      {/* Quick Reference */}
      <Accordion expanded={expanded === 'quick-reference'} onChange={handleChange('quick-reference')} id="quick-reference">
        <AccordionSummary expandIcon={<ExpandMore />}>
          <Box display="flex" alignItems="center" gap={2}>
            <CheckCircle color="primary" />
            <Typography variant="h5" fontWeight="bold">Appendix: Quick Reference</Typography>
          </Box>
        </AccordionSummary>
        <AccordionDetails>
          <TableContainer component={Paper}>
            <Table size="small">
              <TableBody>
                <TableRow>
                  <TableCell><strong>Point Values</strong></TableCell>
                  <TableCell>Win +5 | KO/TKO +8 | Loss −3 | Draw 0</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Tier Thresholds</strong></TableCell>
                  <TableCell>Amateur 0–29 | Semi‑Pro 30–69 | Pro 70–139 | Contender 140–279 | Elite 280+</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Matchmaking</strong></TableCell>
                  <TableCell>Same weight/tier | Rank within 3 | Points within 30 | Timezones within 4h</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Demotion</strong></TableCell>
                  <TableCell>4 consecutive losses → drop 1 tier | Re‑promotion: 5 consecutive wins</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Scheduling</strong></TableCell>
                  <TableCell>Mandatory: complete within 7 days | Scheduled fights: up to 4 weeks ahead | Camps: 72 hours; none within 3 days of a fight</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell><strong>Sim Highlights</strong></TableCell>
                  <TableCell>Pace 35–70/rd | ≥20% jabs | No spam | 3 KD Rule | Fouls/cuts on | 10‑Point Must | Macros banned</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </TableContainer>
          <Divider sx={{ my: 3 }} />
          <Typography variant="h6" gutterBottom>Versioning & Changelog</Typography>
          <Typography variant="body2" paragraph>
            <strong>v1.0 (2025‑11‑16):</strong> Initial TBC‑CFL consolidation: tiers, points, rankings, matchmaking, tournaments, camps, callouts, scheduling, promotion/demotion, sim standard, conduct, and quick reference.
          </Typography>
        </AccordionDetails>
      </Accordion>

      {/* Footer */}
      <Paper elevation={2} sx={{ p: 3, mt: 4, textAlign: 'center', bgcolor: 'background.default' }}>
        <Typography variant="body2" color="text.secondary">
          For questions or clarifications, contact league administrators or check the News feed for updates.
        </Typography>
      </Paper>
    </Container>
    );
  } catch (error) {
    console.error('RulesGuidelines component error:', error);
    return (
      <Container maxWidth="lg" sx={{ py: 4 }}>
        <Alert severity="error">
          Error loading Rules/Guidelines: {error instanceof Error ? error.message : 'Unknown error'}
        </Alert>
      </Container>
    );
  }
};

// Rules/Guidelines component for Creative Fighter League
export default RulesGuidelines;

