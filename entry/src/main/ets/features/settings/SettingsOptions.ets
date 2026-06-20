import {
  APP_MODE_PROXY_ONLY,
  APP_MODE_VPN,
  DEFAULT_DELAY_TEST_URL,
  DEFAULT_HEV_TUN_RW_TIMEOUT,
  DEFAULT_IP_API_URL,
  DEFAULT_VPN_MTU,
  HEV_TUN_LOG_LEVEL_DEBUG,
  HEV_TUN_LOG_LEVEL_ERROR,
  HEV_TUN_LOG_LEVEL_INFO,
  HEV_TUN_LOG_LEVEL_WARN,
  OUTBOUND_DOMAIN_RESOLVE_DNS_HOSTS,
  OUTBOUND_DOMAIN_RESOLVE_NONE,
  OUTBOUND_DOMAIN_RESOLVE_REPLACE,
  UI_MODE_NIGHT_DARK,
  UI_MODE_NIGHT_LIGHT,
  UI_MODE_NIGHT_SYSTEM,
  VPN_BYPASS_LAN_BYPASS,
  VPN_BYPASS_LAN_FOLLOW_CONFIG,
  VPN_BYPASS_LAN_PROXY
} from '../../core/Profile';

/**
 * 设置项「选择」「输入」弹窗的数据模型（底部抽屉用）。
 *
 * 纯数据：每个选项配一句说明（descKey），抽屉标题下配一句提示（hintKey），
 * 由 Settings 页按当前值高亮当前项、点选即写回。值（value）复用 Profile /
 * V2rayNgOptions 既有常量，避免与持久化层分叉。动态选项（VPN 接口地址、
 * 分片 packets）选项随运行期数组变化，由页面就地构建，不在此声明。
 *
 * 采用「带 key 的数组 + 线性查找」而非 Record：ArkTS 不会把 Record 值类型
 * 透传给嵌套对象字面量（arkts-no-untyped-obj-literals），数组元素类型可透传，
 * 与 SettingsCatalog 一致。
 */

/** 单个选择项：值 + 标题 i18n + 一句说明 i18n（descKey 为空串则不显示说明）。 */
export interface SettingChoice {
  value: string;
  labelKey: string;
  descKey: string;
}

/** 选择弹窗规格：抽屉副标题 + 选项清单。 */
export interface SettingSelectSpec {
  key: string;
  hintKey: string;
  choices: SettingChoice[];
}

/** 输入弹窗规格：副标题 / 单位 / 取值范围 / 默认值（用于「恢复默认」，空串则不提供）。 */
export interface SettingInputSpec {
  key: string;
  hintKey: string;
  unit: string;
  range: string;
  defaultValue: string;
}

export const SETTING_SELECTS: SettingSelectSpec[] = [
  {
    key: 'mode',
    hintKey: 'settings.mode.hint',
    choices: [
      { value: APP_MODE_VPN, labelKey: 'settings.mode.vpn', descKey: 'settings.mode.vpn.desc' },
      { value: APP_MODE_PROXY_ONLY, labelKey: 'settings.mode.proxyOnly', descKey: 'settings.mode.proxyOnly.desc' }
    ]
  },
  {
    key: 'uiModeNight',
    hintKey: 'settings.uiModeNight.hint',
    choices: [
      { value: UI_MODE_NIGHT_SYSTEM, labelKey: 'settings.uiModeNight.system', descKey: 'settings.uiModeNight.system.desc' },
      { value: UI_MODE_NIGHT_LIGHT, labelKey: 'settings.uiModeNight.light', descKey: 'settings.uiModeNight.light.desc' },
      { value: UI_MODE_NIGHT_DARK, labelKey: 'settings.uiModeNight.dark', descKey: 'settings.uiModeNight.dark.desc' }
    ]
  },
  {
    key: 'vpnBypassLan',
    hintKey: 'settings.vpnBypassLan.hint',
    choices: [
      { value: VPN_BYPASS_LAN_FOLLOW_CONFIG, labelKey: 'settings.vpnBypassLan.followConfig', descKey: 'settings.vpnBypassLan.followConfig.desc' },
      { value: VPN_BYPASS_LAN_BYPASS, labelKey: 'settings.vpnBypassLan.bypass', descKey: 'settings.vpnBypassLan.bypass.desc' },
      { value: VPN_BYPASS_LAN_PROXY, labelKey: 'settings.vpnBypassLan.proxy', descKey: 'settings.vpnBypassLan.proxy.desc' }
    ]
  },
  {
    key: 'logLevel',
    hintKey: 'settings.logLevel.hint',
    choices: [
      { value: 'debug', labelKey: 'settings.logLevel.debug', descKey: 'settings.logLevel.debug.desc' },
      { value: 'info', labelKey: 'settings.logLevel.info', descKey: 'settings.logLevel.info.desc' },
      { value: 'warning', labelKey: 'settings.logLevel.warning', descKey: 'settings.logLevel.warning.desc' },
      { value: 'error', labelKey: 'settings.logLevel.error', descKey: 'settings.logLevel.error.desc' },
      { value: 'none', labelKey: 'settings.logLevel.none', descKey: 'settings.logLevel.none.desc' }
    ]
  },
  {
    key: 'hevTunLogLevel',
    hintKey: 'settings.hevTunLogLevel.hint',
    choices: [
      { value: HEV_TUN_LOG_LEVEL_ERROR, labelKey: 'settings.hevTunLogLevel.error', descKey: 'settings.hevTunLogLevel.error.desc' },
      { value: HEV_TUN_LOG_LEVEL_WARN, labelKey: 'settings.hevTunLogLevel.warn', descKey: 'settings.hevTunLogLevel.warn.desc' },
      { value: HEV_TUN_LOG_LEVEL_INFO, labelKey: 'settings.hevTunLogLevel.info', descKey: 'settings.hevTunLogLevel.info.desc' },
      { value: HEV_TUN_LOG_LEVEL_DEBUG, labelKey: 'settings.hevTunLogLevel.debug', descKey: 'settings.hevTunLogLevel.debug.desc' }
    ]
  },
  {
    key: 'outboundDomainResolveMethod',
    hintKey: 'settings.outboundDomainResolveMethod.hint',
    choices: [
      { value: OUTBOUND_DOMAIN_RESOLVE_NONE, labelKey: 'settings.outboundDomainResolveMethod.none', descKey: 'settings.outboundDomainResolveMethod.none.desc' },
      { value: OUTBOUND_DOMAIN_RESOLVE_DNS_HOSTS, labelKey: 'settings.outboundDomainResolveMethod.dnsHosts', descKey: 'settings.outboundDomainResolveMethod.dnsHosts.desc' },
      { value: OUTBOUND_DOMAIN_RESOLVE_REPLACE, labelKey: 'settings.outboundDomainResolveMethod.replace', descKey: 'settings.outboundDomainResolveMethod.replace.desc' }
    ]
  },
  {
    key: 'muxXudpQuic',
    hintKey: 'settings.muxXudpQuic.hint',
    choices: [
      { value: 'reject', labelKey: 'settings.muxXudpQuic.reject', descKey: 'settings.muxXudpQuic.reject.desc' },
      { value: 'allow', labelKey: 'settings.muxXudpQuic.allow', descKey: 'settings.muxXudpQuic.allow.desc' },
      { value: 'skip', labelKey: 'settings.muxXudpQuic.skip', descKey: 'settings.muxXudpQuic.skip.desc' }
    ]
  }
];

export const SETTING_INPUTS: SettingInputSpec[] = [
  { key: 'localSocksPort', hintKey: '', unit: '', range: '1–65535', defaultValue: '10808' },
  { key: 'localDnsPort', hintKey: '', unit: '', range: '1–65535', defaultValue: '10853' },
  { key: 'vpnMtu', hintKey: '', unit: 'bytes', range: '576–9000', defaultValue: DEFAULT_VPN_MTU.toString() },
  { key: 'hevTunRwTimeout', hintKey: '', unit: '', range: 'tcp,udp', defaultValue: DEFAULT_HEV_TUN_RW_TIMEOUT },
  { key: 'muxConcurrency', hintKey: '', unit: '', range: '-1–1024', defaultValue: '8' },
  { key: 'muxXudpConcurrency', hintKey: '', unit: '', range: '-1–1024', defaultValue: '8' },
  { key: 'realPingConcurrency', hintKey: '', unit: '', range: '', defaultValue: '16' },
  { key: 'fragmentLength', hintKey: '', unit: '', range: '', defaultValue: '50-100' },
  { key: 'fragmentInterval', hintKey: '', unit: '', range: '', defaultValue: '10-20' },
  { key: 'remoteDns', hintKey: '', unit: '', range: '', defaultValue: '1.1.1.1' },
  { key: 'domesticDns', hintKey: '', unit: '', range: '', defaultValue: '223.5.5.5' },
  { key: 'vpnDns', hintKey: '', unit: '', range: '', defaultValue: '1.1.1.1' },
  { key: 'delayTestUrl', hintKey: '', unit: '', range: '', defaultValue: DEFAULT_DELAY_TEST_URL },
  { key: 'ipApiUrl', hintKey: '', unit: '', range: '', defaultValue: DEFAULT_IP_API_URL }
];

export function findSelectSpec(key: string): SettingSelectSpec | undefined {
  for (let index = 0; index < SETTING_SELECTS.length; index++) {
    if (SETTING_SELECTS[index].key === key) {
      return SETTING_SELECTS[index];
    }
  }
  return undefined;
}

export function findInputSpec(key: string): SettingInputSpec | undefined {
  for (let index = 0; index < SETTING_INPUTS.length; index++) {
    if (SETTING_INPUTS[index].key === key) {
      return SETTING_INPUTS[index];
    }
  }
  return undefined;
}
