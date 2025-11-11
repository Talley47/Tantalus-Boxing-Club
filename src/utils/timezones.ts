// Common timezones list for selection
export const COMMON_TIMEZONES = [
  { value: 'UTC', label: 'UTC (Coordinated Universal Time)' },
  { value: 'America/New_York', label: 'Eastern Time (ET)' },
  { value: 'America/Chicago', label: 'Central Time (CT)' },
  { value: 'America/Denver', label: 'Mountain Time (MT)' },
  { value: 'America/Los_Angeles', label: 'Pacific Time (PT)' },
  { value: 'America/Phoenix', label: 'Arizona Time (MST)' },
  { value: 'America/Anchorage', label: 'Alaska Time (AKT)' },
  { value: 'Pacific/Honolulu', label: 'Hawaii Time (HST)' },
  { value: 'America/Toronto', label: 'Toronto, Canada (EST)' },
  { value: 'America/Vancouver', label: 'Vancouver, Canada (PST)' },
  { value: 'America/Mexico_City', label: 'Mexico City (CST)' },
  { value: 'America/Sao_Paulo', label: 'São Paulo, Brazil (BRT)' },
  { value: 'Europe/London', label: 'London, UK (GMT)' },
  { value: 'Europe/Paris', label: 'Paris, France (CET)' },
  { value: 'Europe/Berlin', label: 'Berlin, Germany (CET)' },
  { value: 'Europe/Madrid', label: 'Madrid, Spain (CET)' },
  { value: 'Europe/Rome', label: 'Rome, Italy (CET)' },
  { value: 'Europe/Amsterdam', label: 'Amsterdam, Netherlands (CET)' },
  { value: 'Europe/Stockholm', label: 'Stockholm, Sweden (CET)' },
  { value: 'Europe/Moscow', label: 'Moscow, Russia (MSK)' },
  { value: 'Asia/Dubai', label: 'Dubai, UAE (GST)' },
  { value: 'Asia/Tokyo', label: 'Tokyo, Japan (JST)' },
  { value: 'Asia/Shanghai', label: 'Shanghai, China (CST)' },
  { value: 'Asia/Hong_Kong', label: 'Hong Kong (HKT)' },
  { value: 'Asia/Singapore', label: 'Singapore (SGT)' },
  { value: 'Asia/Seoul', label: 'Seoul, South Korea (KST)' },
  { value: 'Asia/Mumbai', label: 'Mumbai, India (IST)' },
  { value: 'Asia/Bangkok', label: 'Bangkok, Thailand (ICT)' },
  { value: 'Asia/Manila', label: 'Manila, Philippines (PHT)' },
  { value: 'Australia/Sydney', label: 'Sydney, Australia (AEDT)' },
  { value: 'Australia/Melbourne', label: 'Melbourne, Australia (AEDT)' },
  { value: 'Australia/Brisbane', label: 'Brisbane, Australia (AEST)' },
  { value: 'Australia/Perth', label: 'Perth, Australia (AWST)' },
  { value: 'Pacific/Auckland', label: 'Auckland, New Zealand (NZDT)' },
  { value: 'Africa/Johannesburg', label: 'Johannesburg, South Africa (SAST)' },
  { value: 'Africa/Cairo', label: 'Cairo, Egypt (EET)' },
  { value: 'Africa/Lagos', label: 'Lagos, Nigeria (WAT)' },
];

// Get user's timezone automatically
export const getUserTimezone = (): string => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch (error) {
    return 'UTC';
  }
};

// Get timezone label from value
export const getTimezoneLabel = (value: string): string => {
  const timezone = COMMON_TIMEZONES.find(tz => tz.value === value);
  if (timezone) {
    return timezone.label;
  }
  // If not in common list, return formatted version
  return value.replace(/_/g, ' ').replace(/\//g, ' / ');
};

