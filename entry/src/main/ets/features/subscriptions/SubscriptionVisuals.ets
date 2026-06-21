/**
 * 订阅/节点列表的视觉派生工具（纯逻辑，无 UI、无 any）。
 *
 * - 分组卡头像：由名称确定性地取「身份色」+ 取首个有意义字符作为字母标识；
 * - 节点行国旗：优先提取名称里内嵌的国旗 emoji，否则按地区关键字映射，
 *   最后回退地球图标，并给出去掉前缀国旗后的展示名；
 * - 延迟分级：把 ProxyNode 的延迟/状态归一到 5 档，用于信号点与文字着色。
 */
import { ProxyNode } from '../../core/Profile';
import { AppColor } from '../../theme/Theme';

/** 头像调色板：给每个来源一个稳定的品牌色。 */
const AVATAR_COLORS: Array<string> = ['#5B6CF0', '#16A34A', '#8B5CF6', '#0EA5E9', '#E0457B', '#D97706', '#0D9488'];

/** 由名称做一个稳定哈希，取一个头像色。 */
export function avatarColor(name: string): string {
  let hash = 0;
  for (let index = 0; index < name.length; index++) {
    hash = (hash * 31 + name.charCodeAt(index)) >>> 0;
  }
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

/** 取首个有意义字符（中文取首字、英文取首字母大写）作为字母标识。 */
export function monogram(name: string): string {
  for (let index = 0; index < name.length; index++) {
    const ch = name.charAt(index);
    if (/[A-Za-z一-龥]/.test(ch)) {
      return ch.toUpperCase();
    }
  }
  const first = name.trim().charAt(0);
  return first.length > 0 ? first.toUpperCase() : '#';
}

interface RegionFlag {
  pattern: RegExp;
  flag: string;
}

/** 地区关键字 → 国旗（名称里没有内嵌国旗时的兜底映射）。 */
const REGION_FLAGS: Array<RegionFlag> = [
  { pattern: /香港|hong\s?kong|hk\b/i, flag: '🇭🇰' },
  { pattern: /台湾|台灣|taiwan|tw\b/i, flag: '🇹🇼' },
  { pattern: /日本|东京|東京|tokyo|japan|jp\b/i, flag: '🇯🇵' },
  { pattern: /新加坡|狮城|singapore|sg\b/i, flag: '🇸🇬' },
  { pattern: /韩国|韓國|首尔|首爾|seoul|korea|kr\b/i, flag: '🇰🇷' },
  { pattern: /美国|美國|洛杉矶|硅谷|united\s?states|america|usa|us\b/i, flag: '🇺🇸' },
  { pattern: /英国|英國|伦敦|倫敦|london|united\s?kingdom|uk\b|gb\b/i, flag: '🇬🇧' },
  { pattern: /德国|德國|法兰克福|法蘭克福|frankfurt|germany|de\b/i, flag: '🇩🇪' },
  { pattern: /法国|法國|巴黎|paris|france|fr\b/i, flag: '🇫🇷' },
  { pattern: /俄罗斯|俄羅斯|莫斯科|russia|moscow|ru\b/i, flag: '🇷🇺' },
  { pattern: /印度|india|mumbai|in\b/i, flag: '🇮🇳' },
  { pattern: /加拿大|canada|ca\b/i, flag: '🇨🇦' },
  { pattern: /澳大利亚|澳洲|australia|sydney|au\b/i, flag: '🇦🇺' },
  { pattern: /荷兰|荷蘭|阿姆斯特丹|netherlands|amsterdam|nl\b/i, flag: '🇳🇱' },
  { pattern: /土耳其|turkey|istanbul|tr\b/i, flag: '🇹🇷' },
  { pattern: /马来|馬來|malaysia|my\b/i, flag: '🇲🇾' },
  { pattern: /泰国|泰國|thailand|th\b/i, flag: '🇹🇭' },
  { pattern: /越南|vietnam|vn\b/i, flag: '🇻🇳' },
  { pattern: /菲律宾|菲律賓|philippines|ph\b/i, flag: '🇵🇭' },
  { pattern: /中国|中國|大陆|大陸|china|cn\b/i, flag: '🇨🇳' }
];

const REGIONAL_INDICATOR_START: number = 0x1F1E6;
const REGIONAL_INDICATOR_END: number = 0x1F1FF;

function isRegionalIndicator(codePoint: number | undefined): boolean {
  return codePoint !== undefined && codePoint >= REGIONAL_INDICATOR_START && codePoint <= REGIONAL_INDICATOR_END;
}

/** 提取名称开头内嵌的国旗 emoji（两个区域指示符，UTF-16 共 4 个码元）。 */
function leadingFlag(name: string): string {
  const trimmed = name.trimStart();
  if (!isRegionalIndicator(trimmed.codePointAt(0))) {
    return '';
  }
  if (!isRegionalIndicator(trimmed.codePointAt(2))) {
    return '';
  }
  return trimmed.substring(0, 4);
}

export interface NodePresentation {
  flag: string;
  label: string;
}

/** 计算节点行展示：国旗 + 去掉前缀国旗的名称。 */
export function nodePresentation(name: string): NodePresentation {
  const embedded = leadingFlag(name);
  if (embedded.length > 0) {
    // 去掉内嵌国旗及其后紧跟的分隔符，避免与左侧国旗重复。
    const label = name.trimStart().substring(4).replace(/^[\s·\-|_]+/, '').trim();
    return { flag: embedded, label: label.length > 0 ? label : name.trim() };
  }
  for (let index = 0; index < REGION_FLAGS.length; index++) {
    if (REGION_FLAGS[index].pattern.test(name)) {
      return { flag: REGION_FLAGS[index].flag, label: name.trim() };
    }
  }
  return { flag: '🌐', label: name.trim() };
}

export type NodeDelayLevel = 'good' | 'warn' | 'bad' | 'testing' | 'pending';

/** 把节点的延迟/状态归一到 5 档（与设计稿阈值一致：≤300 绿 / ≤900 橙 / 失败红 / testing 橙）。 */
export function nodeDelayLevel(node: ProxyNode): NodeDelayLevel {
  if (node.delayStatus === 'testing') {
    return 'testing';
  }
  if (node.delayMs >= 0) {
    if (node.delayMs <= 300) {
      return 'good';
    }
    if (node.delayMs <= 900) {
      return 'warn';
    }
    return 'bad';
  }
  if (node.delayStatus.length > 0) {
    return 'bad';
  }
  return 'pending';
}

/** 延迟档位 → 主题色（自动适配明暗）。 */
export function delayLevelColor(level: NodeDelayLevel): ResourceColor {
  if (level === 'good') {
    return AppColor.success;
  }
  if (level === 'warn') {
    return AppColor.warning;
  }
  if (level === 'bad') {
    return AppColor.danger;
  }
  if (level === 'testing') {
    return AppColor.brand;
  }
  return AppColor.textTertiary;
}
