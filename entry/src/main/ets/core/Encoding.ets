import { util } from '@kit.ArkTS';

function stripWhitespace(value: string): string {
  let result = '';
  for (let index = 0; index < value.length; index++) {
    const ch = value.charAt(index);
    if (ch !== ' ' && ch !== '\n' && ch !== '\r' && ch !== '\t') {
      result += ch;
    }
  }
  return result;
}

function padBase64(value: string): string {
  let result = stripWhitespace(value);
  const remainder = result.length % 4;
  if (remainder === 2) {
    result += '==';
  } else if (remainder === 3) {
    result += '=';
  }
  return result;
}

export function decodeBase64ToUtf8(value: string): string {
  const helper = new util.Base64Helper();
  const decoder = util.TextDecoder.create('utf-8');
  const padded = padBase64(value);

  try {
    return decoder.decodeToString(helper.decodeSync(padded, util.Type.BASIC));
  } catch (error) {
    return decoder.decodeToString(helper.decodeSync(padded, util.Type.BASIC_URL_SAFE));
  }
}

export function encodeUtf8ToBase64(value: string): string {
  const encoder = util.TextEncoder.create('utf-8');
  const helper = new util.Base64Helper();
  return helper.encodeToStringSync(encoder.encodeInto(value), util.Type.BASIC);
}
