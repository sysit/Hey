import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { vpnExtension, VpnExtensionAbility } from '@kit.NetworkKit';
import Want from '@ohos.app.ability.Want';
import { DEFAULT_SOCKS_PORT } from '../core/XrayConfig';
import {
  createDefaultVpnConfig,
  VPN_MTU
} from './VpnConstants';
import {
  startNativeTun2Socks,
  startNativeXray,
  stopNativeTun2Socks,
  stopNativeXray,
  validateNativeConfig
} from '../native/HeyNative';

const LOG_DOMAIN: number = 0x0001;
const LOG_TAG: string = 'HeyVpnAbility';

export default class HeyVpnAbility extends VpnExtensionAbility {
  private vpnConnection: vpnExtension.VpnConnection | null = null;
  private tunFd: number = -1;

  onCreate(want: Want): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'VPN ability created.');
    this.startVpn(want);
  }

  onDestroy(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'VPN ability destroying.');
    this.cleanup();
  }

  private async startVpn(want: Want): Promise<void> {
    const configJson = this.getStringParameter(want, 'xrayConfigJson', '');
    const socksHost = this.getStringParameter(want, 'socksHost', '127.0.0.1');
    const socksPort = this.getNumberParameter(want, 'socksPort', DEFAULT_SOCKS_PORT);

    try {
      const validation = validateNativeConfig(configJson);
      if (!validation.ok) {
        throw new Error(validation.message);
      }

      this.vpnConnection = vpnExtension.createVpnConnection(this.context);
      this.tunFd = await this.vpnConnection.create(createDefaultVpnConfig());
      hilog.info(LOG_DOMAIN, LOG_TAG, 'VPN created, tun fd=%{public}d.', this.tunFd);

      const xrayResult = startNativeXray(configJson);
      if (!xrayResult.ok) {
        throw new Error(xrayResult.message);
      }

      const tunResult = startNativeTun2Socks(this.tunFd, socksHost, socksPort, VPN_MTU);
      if (!tunResult.ok) {
        throw new Error(tunResult.message);
      }

      hilog.info(LOG_DOMAIN, LOG_TAG, 'Native VPN bridge started.');
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'VPN start failed: %{public}s', JSON.stringify(error));
      await this.cleanup();
    }
  }

  private getStringParameter(want: Want, key: string, fallback: string): string {
    const value = want.parameters?.[key];
    if (value === undefined || value === null) {
      return fallback;
    }
    return value.toString();
  }

  private getNumberParameter(want: Want, key: string, fallback: number): number {
    const value = want.parameters?.[key];
    if (value === undefined || value === null) {
      return fallback;
    }
    const parsed = Number(value.toString());
    if (Number.isNaN(parsed)) {
      return fallback;
    }
    return parsed;
  }

  private async cleanup(): Promise<void> {
    const tunResult = stopNativeTun2Socks();
    hilog.info(LOG_DOMAIN, LOG_TAG, 'tun2socks stop: %{public}s', tunResult.message);

    const xrayResult = stopNativeXray();
    hilog.info(LOG_DOMAIN, LOG_TAG, 'xray stop: %{public}s', xrayResult.message);

    if (this.vpnConnection !== null) {
      try {
        await this.vpnConnection.destroy();
        hilog.info(LOG_DOMAIN, LOG_TAG, 'VPN destroyed.');
      } catch (error) {
        const businessError = error as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, 'VPN destroy failed: %{public}s', businessError.message ?? JSON.stringify(error));
      }
    }

    this.vpnConnection = null;
    this.tunFd = -1;
  }
}
