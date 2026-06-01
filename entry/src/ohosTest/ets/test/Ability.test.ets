import { describe, it, expect } from '@ohos/hypium';
import { buildXrayConfig } from '../../../main/ets/core/XrayConfig';
import { BUNDLE_NAME, createStopVpnWant, createVpnWant, VPN_ABILITY_NAME } from '../../../main/ets/vpn/VpnConstants';

const OUTBOUND_JSON: string =
  '{"protocol":"vless","tag":"proxy","settings":{"vnext":[{"address":"example.com","port":443,"users":[{"id":"00000000-0000-0000-0000-000000000000","encryption":"none"}]}]}}';

export default function abilityTest() {
  describe('HeyVpnAbility wiring', () => {
    it('creates a start want targeting the vpn extension', 0, () => {
      const config = buildXrayConfig(OUTBOUND_JSON, 10901);
      const want = createVpnWant(config.configJson, config.socksHost, config.socksPort);
      expect(want.bundleName).assertEqual(BUNDLE_NAME);
      expect(want.abilityName).assertEqual(VPN_ABILITY_NAME);
      expect(want.parameters?.['xrayConfigJson']?.toString()).assertContain('"outbounds"');
    });

    it('creates a stop want targeting the vpn extension', 0, () => {
      const want = createStopVpnWant();
      expect(want.bundleName).assertEqual(BUNDLE_NAME);
      expect(want.abilityName).assertEqual(VPN_ABILITY_NAME);
    });
  });
}
