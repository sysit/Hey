import { vpnExtension } from '@kit.NetworkKit';
import Want from '@ohos.app.ability.Want';

export const BUNDLE_NAME: string = 'com.lmlm.hey';
export const VPN_ABILITY_NAME: string = 'HeyVpnAbility';
export const VPN_COMMAND_KEY: string = 'command';
export const VPN_COMMAND_STOP: string = 'stop';
export const VPN_MTU: number = 1400;
export const TUN_IPV4: string = '172.19.0.2';
export const VPN_INTERFACE_NAME: string = 'vpn-tun';

export function createVpnWant(configJson: string): Want {
  return {
    deviceId: '',
    bundleName: BUNDLE_NAME,
    abilityName: VPN_ABILITY_NAME,
    parameters: {
      xrayConfigJson: configJson as Object
    }
  };
}

export function createStopVpnWant(): Want {
  return {
    deviceId: '',
    bundleName: BUNDLE_NAME,
    abilityName: VPN_ABILITY_NAME
  };
}

export function createStopCommandVpnWant(): Want {
  return {
    deviceId: '',
    bundleName: BUNDLE_NAME,
    abilityName: VPN_ABILITY_NAME,
    parameters: {
      command: VPN_COMMAND_STOP as Object
    }
  };
}

export function createDefaultVpnConfig(): vpnExtension.VpnConfig {
  return {
    addresses: [
      {
        address: {
          address: TUN_IPV4,
          family: 1
        },
        prefixLength: 30
      }
    ],
    routes: [
      {
        interface: VPN_INTERFACE_NAME,
        destination: {
          address: {
            address: '0.0.0.0',
            family: 1
          },
          prefixLength: 0
        },
        gateway: {
          address: '0.0.0.0',
          family: 1,
          port: 0
        },
        hasGateway: false,
        isDefaultRoute: true
      }
    ],
    dnsAddresses: ['1.1.1.1', '8.8.8.8'],
    mtu: VPN_MTU,
    isIPv4Accepted: true,
    isIPv6Accepted: false,
    blockedApplications: [BUNDLE_NAME]
  };
}
