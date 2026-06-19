export function filterLogItems(items: Array<string>, query: string): Array<string> {
  const keyword = query.trim();
  if (keyword.length === 0) {
    return copyLogItems(items);
  }
  const result = new Array<string>();
  for (let index = 0; index < items.length; index++) {
    if (items[index].indexOf(keyword) >= 0) {
      result.push(items[index]);
    }
  }
  return result;
}

export function formatLogcatText(items: Array<string>): string {
  return items.join('\n');
}

function copyLogItems(items: Array<string>): Array<string> {
  const result = new Array<string>();
  for (let index = 0; index < items.length; index++) {
    result.push(items[index]);
  }
  return result;
}
