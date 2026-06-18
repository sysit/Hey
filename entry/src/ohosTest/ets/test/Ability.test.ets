import { describe, it, expect } from '@ohos/hypium';
import { buildXrayConfig } from '../../../main/ets/core/XrayConfig';
import {
  BUNDLE_NAME,
  createDefaultVpnConfig,
  createStopCommandVpnWant,
  createStopVpnWant,
  createVpnWant,
  normalizeVpnDnsAddresses,
  VPN_ABILITY_NAME,
  VPN_COMMAND_KEY,
  VPN_COMMAND_STOP
} from '../../../main/ets/vpn/VpnConstants';

const OUTBOUND_JSON: string =
  '{"protocol":"vless","tag":"proxy","settings":{"vnext":[{"address":"example.com","port":443,"users":[{"id":"00000000-0000-0000-0000-000000000000","encryption":"none"}]}]}}';

export default function abilityTest() {
  describe('HeyVpnAbility wiring', () => {
    it('creates a start want targeting the vpn extension', 0, () => {
      const config = buildXrayConfig(OUTBOUND_JSON);
      const want = createVpnWant(config.configJson);
      expect(want.bundleName).assertEqual(BUNDLE_NAME);
      expect(want.abilityName).assertEqual(VPN_ABILITY_NAME);
      expect(want.parameters?.['xrayConfigJson']?.toString()).assertContain('"outbounds"');
      expect(want.parameters?.['socksHost'] === undefined).assertTrue();
      expect(want.parameters?.['socksPort'] === undefined).assertTrue();
    });

    it('creates a stop want targeting the vpn extension', 0, () => {
      const want = createStopVpnWant();
      expect(want.bundleName).assertEqual(BUNDLE_NAME);
      expect(want.abilityName).assertEqual(VPN_ABILITY_NAME);
    });

    it('creates a stop command want targeting the running vpn extension', 0, () => {
      const want = createStopCommandVpnWant();
      expect(want.bundleName).assertEqual(BUNDLE_NAME);
      expect(want.abilityName).assertEqual(VPN_ABILITY_NAME);
      expect(want.parameters?.[VPN_COMMAND_KEY]?.toString()).assertEqual(VPN_COMMAND_STOP);
    });

    it('normalizes vpn dns settings for the vpn interface', 0, () => {
      expect(normalizeVpnDnsAddresses('').join('|')).assertEqual('1.1.1.1|8.8.8.8');
      expect(normalizeVpnDnsAddresses('9.9.9.9, 1.0.0.1, 9.9.9.9').join('|')).assertEqual('9.9.9.9|1.0.0.1');

      const config = createDefaultVpnConfig(false, true, [], '9.9.9.9, 1.0.0.1');
      const dnsAddresses = config.dnsAddresses === undefined ? [] : config.dnsAddresses;
      expect(dnsAddresses.join('|')).assertEqual('9.9.9.9|1.0.0.1');
      expect(config.blockedApplications?.join('|')).assertEqual(BUNDLE_NAME);
    });
  });
}
