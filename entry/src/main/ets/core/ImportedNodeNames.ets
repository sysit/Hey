export function resolveImportedNodeName(outboundJson: string, fallback: string): string {
  let nodeName = fallback.trim().length > 0 ? fallback.trim() : '链接导入';
  try {
    const obj = JSON.parse(outboundJson) as Record<string, Object>;
    if (obj.tag && typeof obj.tag === 'string' && obj.tag.trim().length > 0) {
      nodeName = obj.tag.trim();
    } else if (obj.remarks && typeof obj.remarks === 'string' && obj.remarks.trim().length > 0) {
      nodeName = obj.remarks.trim();
    } else if (obj.name && typeof obj.name === 'string' && obj.name.trim().length > 0) {
      nodeName = obj.name.trim();
    }
  } catch (err) {
    // Keep fallback.
  }
  return nodeName;
}
