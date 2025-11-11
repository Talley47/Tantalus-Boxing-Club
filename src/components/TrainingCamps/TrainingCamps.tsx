import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Avatar,
  Alert,
  Paper,
  Divider,
  Grid,
  LinearProgress,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  Add,
  FitnessCenter,
  GpsFixed,
  TrendingUp,
  Schedule,
  AccessTime,
  LocationOn,
  Person,
  Edit,
  Delete,
  ExpandMore,
  PlayArrow,
  Pause,
  Stop,
  Star,
  StarBorder,
  Timer,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { mediaService } from '../../services/mediaService';
import { TrainingCamp, TrainingObjective, TrainingLog } from '../../types';
// Import Logo1.png
import logo1 from '../../Logo1.png';

const TrainingCamps: React.FC = () => {
  const { fighterProfile } = useAuth();
  const [trainingCamps, setTrainingCamps] = useState<TrainingCamp[]>([]);
  const [objectives, setObjectives] = useState<TrainingObjective[]>([]);
  const [trainingLogs, setTrainingLogs] = useState<TrainingLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [campDialogOpen, setCampDialogOpen] = useState(false);
  const [objectiveDialogOpen, setObjectiveDialogOpen] = useState(false);
  const [logDialogOpen, setLogDialogOpen] = useState(false);
  const [selectedCamp, setSelectedCamp] = useState<TrainingCamp | null>(null);
  const [campForm, setCampForm] = useState({
    name: '',
    description: '',
    difficulty: 'Beginner' as 'Beginner' | 'Intermediate' | 'Advanced' | 'Elite',
    duration_days: 7,
    points_reward: 10
  });
  const [objectiveForm, setObjectiveForm] = useState({
    title: '',
    description: '',
    type: 'Fitness' as 'Fitness' | 'Technique' | 'Strategy' | 'Mental',
    points_reward: 5,
    order_index: 1
  });
  const [logForm, setLogForm] = useState({
    camp_id: '',
    objective_id: '',
    notes: '',
    proof_url: ''
  });

  useEffect(() => {
    if (fighterProfile) {
      loadTrainingData();
    }
  }, [fighterProfile]);

  const loadTrainingData = async () => {
    if (!fighterProfile) return;
    
    try {
      setLoading(true);
      
      // Load training camps
      const camps = await mediaService.getTrainingCamps(fighterProfile.id);
      setTrainingCamps(camps);
      
      // Load objectives for selected camp
      if (selectedCamp) {
        const objectiveData = await mediaService.getTrainingObjectives(selectedCamp.id);
        setObjectives(objectiveData);
      }
      
      // Load training logs
      const logs = await mediaService.getTrainingLogs(fighterProfile.id);
      setTrainingLogs(logs);
    } catch (error) {
      console.error('Error loading training data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateCamp = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.createTrainingCamp({
        created_by: fighterProfile.id,
        name: campForm.name,
        description: campForm.description,
        difficulty: campForm.difficulty,
        duration_days: campForm.duration_days,
        points_reward: campForm.points_reward
      });
      
      setCampDialogOpen(false);
      setCampForm({
        name: '',
        description: '',
        difficulty: 'Beginner',
        duration_days: 7,
        points_reward: 10
      });
      loadTrainingData();
      alert('Training camp created successfully!');
    } catch (error) {
      console.error('Error creating training camp:', error);
      alert('Failed to create training camp');
    }
  };

  const handleCreateObjective = async () => {
    if (!selectedCamp) return;
    
    try {
      await mediaService.createTrainingObjective({
        camp_id: selectedCamp.id,
        title: objectiveForm.title,
        description: objectiveForm.description,
        type: objectiveForm.type,
        points_reward: objectiveForm.points_reward,
        order_index: objectiveForm.order_index
      });
      
      setObjectiveDialogOpen(false);
      setObjectiveForm({
        title: '',
        description: '',
        type: 'Fitness',
        points_reward: 5,
        order_index: 1
      });
      loadTrainingData();
      alert('Training objective created successfully!');
    } catch (error) {
      console.error('Error creating training objective:', error);
      alert('Failed to create training objective');
    }
  };

  const handleLogTraining = async () => {
    if (!fighterProfile) return;
    
    try {
      await mediaService.logTraining({
        fighter_id: fighterProfile.id,
        camp_id: logForm.camp_id,
        objective_id: logForm.objective_id,
        notes: logForm.notes,
        proof_url: logForm.proof_url
      });
      
      setLogDialogOpen(false);
      setLogForm({
        camp_id: '',
        objective_id: '',
        notes: '',
        proof_url: ''
      });
      loadTrainingData();
      alert('Training logged successfully!');
    } catch (error) {
      console.error('Error logging training:', error);
      alert('Failed to log training');
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner': return 'success';
      case 'Intermediate': return 'info';
      case 'Advanced': return 'warning';
      case 'Elite': return 'error';
      default: return 'default';
    }
  };

  const getObjectiveTypeIcon = (type: string) => {
    switch (type) {
      case 'Fitness': return <FitnessCenter />;
      case 'Technique': return <GpsFixed />;
      case 'Strategy': return <TrendingUp />;
      case 'Mental': return <Person />;
      default: return <FitnessCenter />;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center" gap={2}>
          <Box
            component="img"
            src={logo1}
            alt="Tantalus Boxing League Logo"
            sx={{
              height: { xs: 50, md: 70 },
              width: 'auto',
              objectFit: 'contain',
            }}
          />
          <Typography variant="h4">
            Training Camps
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => setCampDialogOpen(true)}
        >
          Create Camp
        </Button>
      </Box>

      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Develop your skills through structured training programs. Complete objectives to earn points and improve your fighting abilities.
      </Typography>

      {/* Training Camps Grid */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr' }, gap: 3, mb: 4 }}>
        {trainingCamps.map((camp) => (
          <Card 
            key={camp.id}
            sx={{ 
              cursor: 'pointer',
              '&:hover': { boxShadow: 4 }
            }}
            onClick={() => setSelectedCamp(camp)}
          >
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <FitnessCenter sx={{ mr: 1 }} />
                <Typography variant="h6">
                  {camp.name}
                </Typography>
              </Box>
              <Typography variant="body2" color="text.secondary" mb={2}>
                {camp.description}
              </Typography>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Chip 
                  label={camp.difficulty} 
                  color={getDifficultyColor(camp.difficulty)}
                  size="small" 
                />
                <Typography variant="body2" color="text.secondary">
                  {camp.duration_days} days
                </Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Typography variant="body2" color="text.secondary">
                  {camp.points_reward} points
                </Typography>
                <Button size="small" variant="outlined">
                  View Details
                </Button>
              </Box>
            </CardContent>
          </Card>
        ))}
      </Box>

      {/* Selected Camp Details */}
      {selectedCamp && (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
              <Typography variant="h5">
                {selectedCamp.name}
              </Typography>
              <Button
                variant="outlined"
                startIcon={<Add />}
                onClick={() => setObjectiveDialogOpen(true)}
              >
                Add Objective
              </Button>
            </Box>
            
            <Typography variant="body1" color="text.secondary" mb={3}>
              {selectedCamp.description}
            </Typography>

            <Box display="flex" gap={2} mb={3}>
              <Chip 
                label={selectedCamp.difficulty} 
                color={getDifficultyColor(selectedCamp.difficulty)}
              />
              <Chip label={`${selectedCamp.duration_days} days`} />
              <Chip label={`${selectedCamp.points_reward} points`} />
            </Box>

            {/* Training Objectives */}
            <Typography variant="h6" gutterBottom>
              Training Objectives
            </Typography>
            {objectives.length === 0 ? (
              <Alert severity="info">No objectives created yet</Alert>
            ) : (
              <List>
                {objectives.map((objective) => (
                  <ListItem key={objective.id}>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          {getObjectiveTypeIcon(objective.type)}
                          <Typography variant="subtitle1">
                            {objective.title}
                          </Typography>
                          <Chip label={objective.type} size="small" />
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" color="text.secondary">
                            {objective.description}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {objective.points_reward} points • Order: {objective.order_index}
                          </Typography>
                        </Box>
                      }
                      secondaryTypographyProps={{ component: 'div' }}
                    />
                    <ListItemSecondaryAction>
                      <Button
                        size="small"
                        variant="outlined"
                        onClick={() => {
                          setLogForm({
                            ...logForm,
                            camp_id: selectedCamp.id,
                            objective_id: objective.id
                          });
                          setLogDialogOpen(true);
                        }}
                      >
                        Log Training
                      </Button>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
            )}
          </CardContent>
        </Card>
      )}

      {/* Training Logs */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Training History
          </Typography>
          {trainingLogs.length === 0 ? (
            <Alert severity="info">No training sessions logged yet</Alert>
          ) : (
            <List>
              {trainingLogs.map((log) => (
                <ListItem key={log.id}>
                  <ListItemText
                    primary={
                      <Box display="flex" alignItems="center" gap={1}>
                        <FitnessCenter />
                        <Typography variant="subtitle1">
                          Training Session
                        </Typography>
                        <Chip label={formatDate(log.completed_at)} size="small" />
                      </Box>
                    }
                    secondary={
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          {log.notes}
                        </Typography>
                        {log.proof_url && (
                          <Typography variant="body2" color="text.secondary">
                            Proof: {log.proof_url}
                          </Typography>
                        )}
                      </Box>
                    }
                  />
                </ListItem>
              ))}
            </List>
          )}
        </CardContent>
      </Card>

      {/* Create Training Camp Dialog */}
      <Dialog open={campDialogOpen} onClose={() => setCampDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create Training Camp</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Camp Name"
              value={campForm.name}
              onChange={(e) => setCampForm({ ...campForm, name: e.target.value })}
            />
            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={campForm.description}
              onChange={(e) => setCampForm({ ...campForm, description: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Difficulty</InputLabel>
              <Select
                value={campForm.difficulty}
                onChange={(e) => setCampForm({ ...campForm, difficulty: e.target.value as any })}
              >
                <MenuItem value="Beginner">Beginner</MenuItem>
                <MenuItem value="Intermediate">Intermediate</MenuItem>
                <MenuItem value="Advanced">Advanced</MenuItem>
                <MenuItem value="Elite">Elite</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Duration (Days)"
              type="number"
              value={campForm.duration_days}
              onChange={(e) => setCampForm({ ...campForm, duration_days: parseInt(e.target.value) })}
            />
            <TextField
              fullWidth
              label="Points Reward"
              type="number"
              value={campForm.points_reward}
              onChange={(e) => setCampForm({ ...campForm, points_reward: parseInt(e.target.value) })}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCampDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreateCamp} variant="contained">
            Create Camp
          </Button>
        </DialogActions>
      </Dialog>

      {/* Create Training Objective Dialog */}
      <Dialog open={objectiveDialogOpen} onClose={() => setObjectiveDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create Training Objective</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Objective Title"
              value={objectiveForm.title}
              onChange={(e) => setObjectiveForm({ ...objectiveForm, title: e.target.value })}
            />
            <TextField
              fullWidth
              label="Description"
              multiline
              rows={3}
              value={objectiveForm.description}
              onChange={(e) => setObjectiveForm({ ...objectiveForm, description: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Type</InputLabel>
              <Select
                value={objectiveForm.type}
                onChange={(e) => setObjectiveForm({ ...objectiveForm, type: e.target.value as any })}
              >
                <MenuItem value="Fitness">Fitness</MenuItem>
                <MenuItem value="Technique">Technique</MenuItem>
                <MenuItem value="Strategy">Strategy</MenuItem>
                <MenuItem value="Mental">Mental</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Points Reward"
              type="number"
              value={objectiveForm.points_reward}
              onChange={(e) => setObjectiveForm({ ...objectiveForm, points_reward: parseInt(e.target.value) })}
            />
            <TextField
              fullWidth
              label="Order Index"
              type="number"
              value={objectiveForm.order_index}
              onChange={(e) => setObjectiveForm({ ...objectiveForm, order_index: parseInt(e.target.value) })}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setObjectiveDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreateObjective} variant="contained">
            Create Objective
          </Button>
        </DialogActions>
      </Dialog>

      {/* Log Training Dialog */}
      <Dialog open={logDialogOpen} onClose={() => setLogDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Log Training Session</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr' }, gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Notes"
              multiline
              rows={3}
              value={logForm.notes}
              onChange={(e) => setLogForm({ ...logForm, notes: e.target.value })}
              placeholder="Describe your training session..."
            />
            <TextField
              fullWidth
              label="Proof URL (Optional)"
              value={logForm.proof_url}
              onChange={(e) => setLogForm({ ...logForm, proof_url: e.target.value })}
              placeholder="Link to video, photo, or other proof of training"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLogDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleLogTraining} variant="contained">
            Log Training
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TrainingCamps;