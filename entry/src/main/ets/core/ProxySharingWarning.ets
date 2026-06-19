import { AppSettings, ConnectionStatus } from './Profile';

export function shouldShowProxySharingStartWarning(settings: AppSettings, status: ConnectionStatus): boolean {
  return settings.proxySharingEnabled && status === ConnectionStatus.RUNNING;
}
