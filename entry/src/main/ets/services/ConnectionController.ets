import { vpnExtension } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConnectionStatus, GeneratedXrayConfig, ProxyProfile, RuntimeStats } from '../core/Profile';
import { buildXrayConfig, validateOutboundJson } from '../core/XrayConfig';
import { createStopVpnWant, createVpnWant } from '../vpn/VpnConstants';
import { getNativeStats } from '../native/HeyNative';

export interface ConnectionSnapshot {
  status: ConnectionStatus;
  startedAt: number;
  lastError: string;
  generatedConfig: GeneratedXrayConfig | null;
}

export class ConnectionController {
  private status: ConnectionStatus = ConnectionStatus.IDLE;
  private startedAt: number = 0;
  private lastError: string = '';
  private generatedConfig: GeneratedXrayConfig | null = null;

  getSnapshot(): ConnectionSnapshot {
    return {
      status: this.status,
      startedAt: this.startedAt,
      lastError: this.lastError,
      generatedConfig: this.generatedConfig
    };
  }

  getStats(): RuntimeStats {
    const stats = getNativeStats();
    if (this.status === ConnectionStatus.RUNNING) {
      return {
        uploadBytes: stats.uploadBytes,
        downloadBytes: stats.downloadBytes,
        xrayRunning: true,
        tun2SocksRunning: true,
        lastMessage: 'VPN extension owns the native bridge. Wire IPC stats after real libXray/tun2socks integration.'
      };
    }
    return stats;
  }

  async start(profile: ProxyProfile): Promise<ConnectionSnapshot> {
    if (this.status === ConnectionStatus.STARTING || this.status === ConnectionStatus.RUNNING) {
      return this.getSnapshot();
    }

    const validation = validateOutboundJson(profile.outboundJson);
    if (!validation.valid) {
      this.status = ConnectionStatus.ERROR;
      this.lastError = validation.message;
      return this.getSnapshot();
    }

    this.status = ConnectionStatus.STARTING;
    this.lastError = '';
    this.generatedConfig = buildXrayConfig(profile.outboundJson);

    try {
      await vpnExtension.startVpnExtensionAbility(createVpnWant(
        this.generatedConfig.configJson,
        this.generatedConfig.socksHost,
        this.generatedConfig.socksPort
      ));
      this.status = ConnectionStatus.RUNNING;
      this.startedAt = Date.now();
    } catch (error) {
      const businessError = error as BusinessError;
      this.status = ConnectionStatus.ERROR;
      this.lastError = `启动 VPN 失败：${businessError.message ?? JSON.stringify(error)}`;
    }
    return this.getSnapshot();
  }

  async stop(): Promise<ConnectionSnapshot> {
    if (this.status === ConnectionStatus.IDLE || this.status === ConnectionStatus.STOPPING) {
      return this.getSnapshot();
    }

    this.status = ConnectionStatus.STOPPING;
    try {
      await vpnExtension.stopVpnExtensionAbility(createStopVpnWant());
      this.status = ConnectionStatus.IDLE;
      this.startedAt = 0;
      this.lastError = '';
    } catch (error) {
      const businessError = error as BusinessError;
      this.status = ConnectionStatus.ERROR;
      this.lastError = `停止 VPN 失败：${businessError.message ?? JSON.stringify(error)}`;
    }
    return this.getSnapshot();
  }
}
