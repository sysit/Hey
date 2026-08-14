import { AppLanguage, RuntimeStats } from './Profile';
import { translate } from './I18n';
import { formatBytes } from '../utils/Formatters';

export const SPEED_NOTIFICATION_REFRESH_INTERVAL_MS: number = 3000;

export interface SpeedNotificationSample {
  at: number;
  uploadBytes: number;
  downloadBytes: number;
}

export interface SpeedNotificationRates {
  uploadBytesPerSecond: number;
  downloadBytesPerSecond: number;
}

export function sampleSpeedNotificationStats(stats: RuntimeStats, at: number): SpeedNotificationSample {
  return {
    at,
    uploadBytes: Math.max(0, Math.floor(stats.uploadBytes)),
    downloadBytes: Math.max(0, Math.floor(stats.downloadBytes))
  };
}

export function calculateSpeedNotificationRates(
  previous: SpeedNotificationSample | null,
  current: SpeedNotificationSample
): SpeedNotificationRates {
  if (previous === null || current.at <= previous.at) {
    return { uploadBytesPerSecond: 0, downloadBytesPerSecond: 0 };
  }

  const seconds = (current.at - previous.at) / 1000;
  return {
    uploadBytesPerSecond: Math.round(Math.max(0, current.uploadBytes - previous.uploadBytes) / seconds),
    downloadBytesPerSecond: Math.round(Math.max(0, current.downloadBytes - previous.downloadBytes) / seconds)
  };
}

export function shouldPublishSpeedNotification(
  now: number,
  lastPublishAt: number,
  published: boolean,
  intervalMs: number = SPEED_NOTIFICATION_REFRESH_INTERVAL_MS
): boolean {
  return !published || lastPublishAt <= 0 || now - lastPublishAt >= intervalMs;
}

export function buildSpeedNotificationText(language: AppLanguage, rates: SpeedNotificationRates): string {
  return `${translate(language, 'home.upload')} ${formatBytes(rates.uploadBytesPerSecond)}/s | ${translate(language, 'home.download')} ${formatBytes(rates.downloadBytesPerSecond)}/s`;
}

export function buildSpeedNotificationAdditionalText(
  language: AppLanguage,
  stats: RuntimeStats,
  elapsedText: string
): string {
  const duration = elapsedText.length > 0 ? elapsedText : '00:00';
  return `${translate(language, 'home.duration')} ${duration} | ${translate(language, 'notification.speed.total')} ${formatBytes(stats.uploadBytes)} / ${formatBytes(stats.downloadBytes)}`;
}
