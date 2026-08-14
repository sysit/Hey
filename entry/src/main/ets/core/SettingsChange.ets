export const RUNTIME_SETTINGS_RESTART_PENDING_KEY: string = 'pendingRuntimeSettingsRestart';

export interface RuntimeSettingsRestartDecision {
  shouldRestart: boolean;
  keepPending: boolean;
}

export function decideRuntimeSettingsRestart(pending: boolean, running: boolean, busy: boolean): RuntimeSettingsRestartDecision {
  if (!pending) {
    return {
      shouldRestart: false,
      keepPending: false
    };
  }
  if (busy) {
    return {
      shouldRestart: false,
      keepPending: true
    };
  }
  if (!running) {
    return {
      shouldRestart: false,
      keepPending: false
    };
  }
  return {
    shouldRestart: true,
    keepPending: false
  };
}

export function markRuntimeSettingsRestartNeeded(): void {
  AppStorage.setOrCreate(RUNTIME_SETTINGS_RESTART_PENDING_KEY, true);
}

export function consumeRuntimeSettingsRestartDecision(running: boolean, busy: boolean): RuntimeSettingsRestartDecision {
  const pending = AppStorage.get<boolean>(RUNTIME_SETTINGS_RESTART_PENDING_KEY) ?? false;
  const decision = decideRuntimeSettingsRestart(pending, running, busy);
  AppStorage.setOrCreate(RUNTIME_SETTINGS_RESTART_PENDING_KEY, decision.keepPending);
  return decision;
}
