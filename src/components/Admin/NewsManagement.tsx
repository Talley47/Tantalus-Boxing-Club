import React, { useState, useEffect, useCallback } from 'react';
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  Chip,
  Alert,
  CircularProgress,
  Switch,
  FormControlLabel,
  Checkbox,
  ImageList,
  ImageListItem,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Article,
  Announcement,
  SportsMma,
  Close,
  CloudUpload,
  AutoAwesome,
} from '@mui/icons-material';
import { NewsService, NewsItem, CreateNewsRequest } from '../../services/newsService';
import { supabase } from '../../services/supabase';

const NewsManagement: React.FC = () => {
  const [newsItems, setNewsItems] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedNews, setSelectedNews] = useState<NewsItem | null>(null);
  const [newsToDelete, setNewsToDelete] = useState<string | null>(null);
  const [formData, setFormData] = useState<CreateNewsRequest>({
    title: '',
    content: '',
    author: 'Mike Glove',
    author_title: 'TBC News Reporter',
    type: 'news',
    priority: 'low',
    images: [],
    featured_image: '',
    tags: [],
    is_featured: false,
    is_published: true,
  });
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [newImageUrl, setNewImageUrl] = useState('');
  const [tags, setTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');
  const [uploadingImage, setUploadingImage] = useState(false);
  const [imageErrors, setImageErrors] = useState<Record<number, boolean>>({});
  const fileInputRef = React.useRef<HTMLInputElement>(null);

  const loadNews = useCallback(async () => {
    try {
      setLoading(true);
      const data = await NewsService.getNewsItems(100, undefined, true); // Include unpublished for admin
      setNewsItems(data);
    } catch (error) {
      console.error('Error loading news:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadNews();
  }, [loadNews]);

  // Subscribe to news changes
  useEffect(() => {
    const channel = supabase
      .channel('news_management')
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'news_announcements' },
        () => {
          loadNews();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [loadNews]);

  const handleCreateNews = () => {
    setSelectedNews(null);
    setFormData({
      title: '',
      content: '',
      author: 'Mike Glove',
      author_title: 'TBC News Reporter',
      type: 'news',
      priority: 'low',
      images: [],
      featured_image: '',
      tags: [],
      is_featured: false,
      is_published: true,
    });
    setImageUrls([]);
    setTags([]);
    setImageErrors({});
    setDialogOpen(true);
  };

  const handleEditNews = (news: NewsItem) => {
    setSelectedNews(news);
    setFormData({
      title: news.title,
      content: news.content,
      author: news.author,
      author_title: news.author_title || 'TBC News Reporter',
      type: news.type,
      priority: news.priority,
      images: news.images || [],
      featured_image: news.featured_image || '',
      tags: news.tags || [],
      is_featured: news.is_featured || false,
      is_published: news.is_published !== false,
    });
    setImageUrls(news.images || []);
    setTags(news.tags || []);
    setImageErrors({});
    setDialogOpen(true);
  };

  const handleSaveNews = async () => {
    try {
      const newsData: CreateNewsRequest = {
        ...formData,
        images: imageUrls,
        tags: tags,
        featured_image: formData.featured_image || (imageUrls.length > 0 ? imageUrls[0] : undefined),
      };

      if (selectedNews) {
        await NewsService.updateNewsItem(selectedNews.id, newsData);
      } else {
        await NewsService.createNewsItem(newsData);
      }

      setDialogOpen(false);
      loadNews();
      alert(selectedNews ? 'News updated successfully!' : 'News published successfully!');
    } catch (error: any) {
      console.error('Error saving news:', error);
      alert('Failed to save news: ' + (error.message || 'Unknown error'));
    }
  };

  const handleGenerateFightResultsNews = async () => {
    try {
      const recentFights = await NewsService.getRecentFightResults(10);
      
      if (recentFights.length === 0) {
        alert('No recent fight results found to generate news.');
        return;
      }

      // Use the auto-generate method
      const fightIds = recentFights.slice(0, 5).map((fight: any) => fight.id);
      await NewsService.autoGenerateFightResultsNews(fightIds);
      loadNews();
      alert('Fight results news generated successfully!');
    } catch (error: any) {
      console.error('Error generating fight results news:', error);
      alert('Failed to generate fight results news: ' + (error.message || 'Unknown error'));
    }
  };

  const handleDeleteNews = async () => {
    if (!newsToDelete) return;

    try {
      await NewsService.deleteNewsItem(newsToDelete);
      setDeleteDialogOpen(false);
      setNewsToDelete(null);
      loadNews();
      alert('News deleted successfully!');
    } catch (error: any) {
      console.error('Error deleting news:', error);
      const errorMessage = error?.message || error?.toString() || 'Unknown error';
      alert(`Failed to delete news: ${errorMessage}`);
    }
  };

  const handleAddImage = () => {
    if (newImageUrl.trim()) {
      setImageUrls([...imageUrls, newImageUrl.trim()]);
      setNewImageUrl('');
    }
  };

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Check if it's an image
    const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedImageTypes.includes(file.type)) {
      alert('Please select an image file (JPEG, PNG, GIF, or WebP)');
      return;
    }

    // Check file size (max 10MB)
    if (file.size > 10 * 1024 * 1024) {
      alert('Image size must be less than 10MB');
      return;
    }

    try {
      setUploadingImage(true);
      
      // Convert to data URL for immediate display and storage
      const reader = new FileReader();
      reader.onloadend = () => {
        const dataUrl = reader.result as string;
        setImageUrls([...imageUrls, dataUrl]);
        setUploadingImage(false);
      };
      reader.onerror = () => {
        console.error('Error reading file');
        alert('Failed to read file');
        setUploadingImage(false);
      };
      reader.readAsDataURL(file);
      
      // Reset file input
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (error) {
      console.error('Error uploading file:', error);
      alert('Failed to upload image');
      setUploadingImage(false);
    }
  };

  const handleRemoveImage = (index: number) => {
    setImageUrls(imageUrls.filter((_, i) => i !== index));
  };

  const handleAddTag = () => {
    if (newTag.trim() && !tags.includes(newTag.trim())) {
      setTags([...tags, newTag.trim()]);
      setNewTag('');
    }
  };

  const handleRemoveTag = (tag: string) => {
    setTags(tags.filter(t => t !== tag));
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'news': return 'primary';
      case 'announcement': return 'warning';
      case 'blog': return 'info';
      case 'fight_result': return 'error';
      default: return 'default';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'error';
      case 'medium': return 'warning';
      case 'low': return 'default';
      default: return 'default';
    }
  };

  return (
    <Card>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
          <Box display="flex" alignItems="center">
            <Article sx={{ mr: 1 }} />
            <Typography variant="h6">News & Announcements Management</Typography>
          </Box>
          <Box display="flex" gap={1}>
            <Button
              variant="outlined"
              startIcon={<AutoAwesome />}
              onClick={handleGenerateFightResultsNews}
            >
              Auto-Generate Fight Results
            </Button>
            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={handleCreateNews}
            >
              Create News
            </Button>
          </Box>
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : newsItems.length === 0 ? (
          <Alert severity="info">No news items created yet</Alert>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Title</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Author</TableCell>
                  <TableCell>Priority</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {newsItems.map((news) => (
                  <TableRow key={news.id}>
                    <TableCell>
                      <Box>
                        <Typography variant="body2" fontWeight="bold">
                          {news.title}
                        </Typography>
                        {news.is_featured && (
                          <Chip label="Featured" size="small" color="primary" sx={{ mt: 0.5 }} />
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={news.type}
                        size="small"
                        color={getTypeColor(news.type) as any}
                      />
                    </TableCell>
                    <TableCell>{news.author}</TableCell>
                    <TableCell>
                      <Chip
                        label={news.priority}
                        size="small"
                        color={getPriorityColor(news.priority) as any}
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={news.is_published ? 'Published' : 'Draft'}
                        size="small"
                        color={news.is_published ? 'success' : 'default'}
                      />
                    </TableCell>
                    <TableCell>
                      <Box>
                        <Typography variant="body2">
                          {news.published_at 
                            ? new Date(news.published_at).toLocaleString('en-US', {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric',
                                hour: 'numeric',
                                minute: '2-digit',
                                hour12: true,
                              })
                            : 'Not published'}
                        </Typography>
                        {news.created_at !== news.published_at && (
                          <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.7rem' }}>
                            Created: {new Date(news.created_at).toLocaleString('en-US', {
                              year: 'numeric',
                              month: 'short',
                              day: 'numeric',
                              hour: 'numeric',
                              minute: '2-digit',
                              hour12: true,
                            })}
                          </Typography>
                        )}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Tooltip title="Edit News">
                        <IconButton
                          size="small"
                          onClick={() => handleEditNews(news)}
                        >
                          <Edit />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete News">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => {
                            setNewsToDelete(news.id);
                            setDeleteDialogOpen(true);
                          }}
                        >
                          <Delete />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>

      {/* Create/Edit News Dialog */}
      <Dialog 
        open={dialogOpen} 
        onClose={() => setDialogOpen(false)} 
        maxWidth="lg" 
        fullWidth
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>
          {selectedNews ? 'Edit News' : 'Create New News/Announcement/Blog'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              fullWidth
              label="Title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />

            <FormControl fullWidth required>
              <InputLabel>Type</InputLabel>
              <Select
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
              >
                <MenuItem value="news">News</MenuItem>
                <MenuItem value="announcement">Announcement</MenuItem>
                <MenuItem value="blog">Blog</MenuItem>
                <MenuItem value="fight_result">Fight Result</MenuItem>
              </Select>
            </FormControl>

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <TextField
                fullWidth
                label="Author"
                value={formData.author}
                onChange={(e) => setFormData({ ...formData, author: e.target.value })}
              />
              <TextField
                fullWidth
                label="Author Title"
                value={formData.author_title}
                onChange={(e) => setFormData({ ...formData, author_title: e.target.value })}
                placeholder="TBC News Reporter"
              />
            </Box>

            <TextField
              fullWidth
              label="Content"
              multiline
              rows={15}
              value={formData.content}
              onChange={(e) => setFormData({ ...formData, content: e.target.value })}
              placeholder="Write your news, announcement, or blog post here... (Unlimited text supported)"
              required
            />

            <FormControl fullWidth>
              <InputLabel>Priority</InputLabel>
              <Select
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value as any })}
              >
                <MenuItem value="low">Low</MenuItem>
                <MenuItem value="medium">Medium</MenuItem>
                <MenuItem value="high">High</MenuItem>
              </Select>
            </FormControl>

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Featured Image URL
              </Typography>
              <TextField
                fullWidth
                value={formData.featured_image}
                onChange={(e) => setFormData({ ...formData, featured_image: e.target.value })}
                placeholder="https://example.com/image.jpg"
              />
            </Box>

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Images (Upload files or add URLs)
              </Typography>
              <Box display="flex" gap={1} mb={2} flexWrap="wrap">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/jpeg,image/jpg,image/png,image/gif,image/webp"
                  onChange={handleFileSelect}
                  style={{ display: 'none' }}
                />
                <Button
                  variant="outlined"
                  startIcon={uploadingImage ? <CircularProgress size={16} /> : <CloudUpload />}
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploadingImage}
                >
                  {uploadingImage ? 'Uploading...' : 'Upload Image'}
                </Button>
                <TextField
                  fullWidth
                  size="small"
                  value={newImageUrl}
                  onChange={(e) => setNewImageUrl(e.target.value)}
                  placeholder="Or enter image URL"
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleAddImage();
                    }
                  }}
                  sx={{ flex: 1, minWidth: 200 }}
                />
                <Button
                  variant="outlined"
                  onClick={handleAddImage}
                  disabled={!newImageUrl.trim()}
                >
                  Add URL
                </Button>
              </Box>
              {imageUrls.length > 0 && (
                <ImageList sx={{ maxHeight: 300 }} cols={3} rowHeight={150}>
                  {imageUrls.map((url, index) => (
                    <ImageListItem key={index} sx={{ position: 'relative' }}>
                      {imageErrors[index] ? (
                        <Box
                          sx={{
                            width: '100%',
                            height: '100%',
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: 'center',
                            justifyContent: 'center',
                            bgcolor: 'grey.100',
                            color: 'text.secondary',
                            p: 1,
                            textAlign: 'center',
                          }}
                        >
                          <Typography variant="caption" sx={{ mb: 1 }}>
                            Image failed to load
                          </Typography>
                          <Typography variant="caption" color="error">
                            (CORS or invalid URL)
                          </Typography>
                          <Button
                            size="small"
                            variant="outlined"
                            onClick={() => {
                              const newErrors = { ...imageErrors };
                              delete newErrors[index];
                              setImageErrors(newErrors);
                            }}
                            sx={{ mt: 1 }}
                          >
                            Retry
                          </Button>
                        </Box>
                      ) : (
                        <img
                          src={url}
                          alt={`Image ${index + 1}`}
                          loading="lazy"
                          style={{ objectFit: 'cover', width: '100%', height: '100%' }}
                          onError={() => {
                            setImageErrors({ ...imageErrors, [index]: true });
                          }}
                        />
                      )}
                      <Box
                        sx={{
                          position: 'absolute',
                          top: 0,
                          right: 0,
                          bgcolor: 'rgba(0,0,0,0.7)',
                          color: 'white',
                          zIndex: 1,
                        }}
                      >
                        <IconButton
                          size="small"
                          onClick={() => {
                            handleRemoveImage(index);
                            const newErrors = { ...imageErrors };
                            delete newErrors[index];
                            setImageErrors(newErrors);
                          }}
                          sx={{ color: 'white' }}
                        >
                          <Close />
                        </IconButton>
                      </Box>
                    </ImageListItem>
                  ))}
                </ImageList>
              )}
            </Box>

            <Box>
              <Typography variant="subtitle2" gutterBottom>
                Tags
              </Typography>
              <Box display="flex" gap={1} mb={1} flexWrap="wrap">
                {tags.map((tag) => (
                  <Chip
                    key={tag}
                    label={tag}
                    onDelete={() => handleRemoveTag(tag)}
                    color="primary"
                    variant="outlined"
                  />
                ))}
              </Box>
              <Box display="flex" gap={1}>
                <TextField
                  fullWidth
                  size="small"
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  placeholder="Enter tag"
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      handleAddTag();
                    }
                  }}
                />
                <Button variant="outlined" onClick={handleAddTag}>
                  Add Tag
                </Button>
              </Box>
            </Box>

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_featured || false}
                    onChange={(e) => setFormData({ ...formData, is_featured: e.target.checked })}
                  />
                }
                label="Featured"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_published !== false}
                    onChange={(e) => setFormData({ ...formData, is_published: e.target.checked })}
                  />
                }
                label="Published"
              />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveNews} variant="contained">
            {selectedNews ? 'Update' : 'Publish'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog 
        open={deleteDialogOpen} 
        onClose={() => setDeleteDialogOpen(false)}
        disableEnforceFocus={false}
        disableAutoFocus={false}
        disableRestoreFocus={false}
        keepMounted={false}
      >
        <DialogTitle>Delete News</DialogTitle>
        <DialogContent>
          <Typography>
            Are you sure you want to delete this news item? This action cannot be undone.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteNews} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
};

export default NewsManagement;

