import heyNative from 'libheyvpn.so';
import { RuntimeStats } from '../core/Profile';

export interface NativeResult {
  ok: boolean;
  message: string;
}

export interface NativePingResult {
  ok: boolean;
  delayMs: number;
  message: string;
}

interface NativeBridge {
  validateConfig(configJson: string): NativeResult;
  setTunFd(tunFd: number): NativeResult;
  startXray(configJson: string, workDir: string): NativeResult;
  stopXray(): NativeResult;
  getStats(): RuntimeStats;
  pingOutbound(configJson: string, datDir: string, url: string, timeoutSeconds: number, proxy: string): NativePingResult;
}

const bridge = heyNative as NativeBridge;

export function validateNativeConfig(configJson: string): NativeResult {
  return bridge.validateConfig(configJson);
}

export function setNativeTunFd(tunFd: number): NativeResult {
  return bridge.setTunFd(tunFd);
}

export function startNativeXray(configJson: string, workDir: string): NativeResult {
  return bridge.startXray(configJson, workDir);
}

export function stopNativeXray(): NativeResult {
  return bridge.stopXray();
}

export function getNativeStats(): RuntimeStats {
  return bridge.getStats();
}

export function pingNativeOutbound(configJson: string, datDir: string, url: string, timeoutSeconds: number, proxy: string): NativePingResult {
  return bridge.pingOutbound(configJson, datDir, url, timeoutSeconds, proxy);
}
