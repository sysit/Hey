import { DEFAULT_LANGUAGE, translate } from './I18n';
import { AppLanguage, ConnectionStatus } from './Profile';

export const CONTROL_CARD_FORM_NAME: string = 'HeyControlCard';
export const CONTROL_CARD_TOGGLE_URI: string = 'hey://toggle';
export const CONTROL_CARD_START_URI: string = 'hey://start';
export const CONTROL_CARD_STOP_URI: string = 'hey://stop';
export const CONTROL_CARD_SCAN_URI: string = 'hey://scan';

export interface ControlCardFormData {
  appName: string;
  subtitle: string;
  toggleUri: string;
  startUri: string;
  stopUri: string;
  scanUri: string;
  statusLabel: string;
  statusDetail: string;
  primaryActionLabel: string;
  primaryActionUri: string;
  statusColor: string;
  statusBackground: string;
  primaryColor: string;
  primaryTextColor: string;
}

export function buildControlCardFormData(
  language: AppLanguage = DEFAULT_LANGUAGE,
  status: ConnectionStatus = ConnectionStatus.IDLE,
  elapsedText: string = '',
  lastError: string = ''
): ControlCardFormData {
  const running = status === ConnectionStatus.RUNNING;
  const busy = status === ConnectionStatus.STARTING || status === ConnectionStatus.STOPPING;
  const error = status === ConnectionStatus.ERROR;
  return {
    appName: 'Hey',
    subtitle: translate(language, 'control.card.subtitle'),
    toggleUri: CONTROL_CARD_TOGGLE_URI,
    startUri: CONTROL_CARD_START_URI,
    stopUri: CONTROL_CARD_STOP_URI,
    scanUri: CONTROL_CARD_SCAN_URI,
    statusLabel: statusLabel(language, status),
    statusDetail: statusDetail(language, status, elapsedText, lastError),
    primaryActionLabel: running ? translate(language, 'action.stop') : translate(language, 'action.start'),
    primaryActionUri: running ? CONTROL_CARD_STOP_URI : CONTROL_CARD_START_URI,
    statusColor: statusColor(running, busy, error),
    statusBackground: statusBackground(running, busy, error),
    primaryColor: running ? '#EF4444' : '#F97316',
    primaryTextColor: '#FFFFFF'
  };
}

export function normalizeControlCardFormData(data: ControlCardFormData | null | undefined): ControlCardFormData {
  if (data === null || data === undefined) {
    return buildControlCardFormData();
  }
  const fallback = buildControlCardFormData();
  return {
    appName: nonEmpty(data.appName, fallback.appName),
    subtitle: nonEmpty(data.subtitle, fallback.subtitle),
    toggleUri: nonEmpty(data.toggleUri, fallback.toggleUri),
    startUri: nonEmpty(data.startUri, fallback.startUri),
    stopUri: nonEmpty(data.stopUri, fallback.stopUri),
    scanUri: nonEmpty(data.scanUri, fallback.scanUri),
    statusLabel: nonEmpty(data.statusLabel, fallback.statusLabel),
    statusDetail: nonEmpty(data.statusDetail, fallback.statusDetail),
    primaryActionLabel: nonEmpty(data.primaryActionLabel, fallback.primaryActionLabel),
    primaryActionUri: nonEmpty(data.primaryActionUri, fallback.primaryActionUri),
    statusColor: nonEmpty(data.statusColor, fallback.statusColor),
    statusBackground: nonEmpty(data.statusBackground, fallback.statusBackground),
    primaryColor: nonEmpty(data.primaryColor, fallback.primaryColor),
    primaryTextColor: nonEmpty(data.primaryTextColor, fallback.primaryTextColor)
  };
}

function statusLabel(language: AppLanguage, status: ConnectionStatus): string {
  switch (status) {
    case ConnectionStatus.STARTING:
      return translate(language, 'status.starting');
    case ConnectionStatus.RUNNING:
      return translate(language, 'status.running');
    case ConnectionStatus.STOPPING:
      return translate(language, 'status.stopping');
    case ConnectionStatus.ERROR:
      return translate(language, 'status.error');
    default:
      return translate(language, 'status.idle');
  }
}

function statusDetail(language: AppLanguage, status: ConnectionStatus, elapsedText: string, lastError: string): string {
  if (status === ConnectionStatus.RUNNING) {
    const elapsed = elapsedText.length > 0 ? elapsedText : '00:00';
    return `${translate(language, 'home.duration')} ${elapsed}`;
  }
  if (status === ConnectionStatus.STARTING || status === ConnectionStatus.STOPPING) {
    return translate(language, 'home.busy');
  }
  if (status === ConnectionStatus.ERROR) {
    return lastError.length > 0 ? lastError : translate(language, 'status.error');
  }
  return translate(language, 'home.ready');
}

function statusColor(running: boolean, busy: boolean, error: boolean): string {
  if (running) {
    return '#15803D';
  }
  if (busy) {
    return '#B45309';
  }
  if (error) {
    return '#B91C1C';
  }
  return '#9A3412';
}

function statusBackground(running: boolean, busy: boolean, error: boolean): string {
  if (running) {
    return '#DCFCE7';
  }
  if (busy) {
    return '#FEF3C7';
  }
  if (error) {
    return '#FEE2E2';
  }
  return '#FED7AA';
}

function nonEmpty(value: string | undefined, fallback: string): string {
  if (value === undefined || value.length === 0) {
    return fallback;
  }
  return value;
}
