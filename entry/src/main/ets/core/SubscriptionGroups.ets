import { ProxyNode, SubscriptionGroup } from './Profile';

export function moveSubscriptionGroup(groups: Array<SubscriptionGroup>, groupId: string, delta: number): Array<SubscriptionGroup> {
  const next = copySubscriptionGroups(groups);
  const fromIndex = findSubscriptionGroupIndex(next, groupId);
  const toIndex = fromIndex + delta;
  if (fromIndex < 0 || toIndex < 0 || toIndex >= next.length) {
    return next;
  }

  const current = next[fromIndex];
  next[fromIndex] = next[toIndex];
  next[toIndex] = current;
  return next;
}

function findSubscriptionGroupIndex(groups: Array<SubscriptionGroup>, groupId: string): number {
  for (let index = 0; index < groups.length; index++) {
    if (groups[index].id === groupId) {
      return index;
    }
  }
  return -1;
}

function copySubscriptionGroups(groups: Array<SubscriptionGroup>): Array<SubscriptionGroup> {
  const copied = new Array<SubscriptionGroup>();
  for (let index = 0; index < groups.length; index++) {
    copied.push(copySubscriptionGroup(groups[index]));
  }
  return copied;
}

function copySubscriptionGroup(group: SubscriptionGroup): SubscriptionGroup {
  return {
    id: group.id,
    name: group.name,
    url: group.url,
    enabled: group.enabled,
    selectedNodeId: group.selectedNodeId,
    nodes: copyProxyNodes(group.nodes),
    updatedAt: group.updatedAt,
    userAgent: group.userAgent,
    filter: group.filter,
    allowInsecureUrl: group.allowInsecureUrl
  };
}

function copyProxyNodes(nodes: Array<ProxyNode>): Array<ProxyNode> {
  const copied = new Array<ProxyNode>();
  for (let index = 0; index < nodes.length; index++) {
    const node = nodes[index];
    copied.push({
      id: node.id,
      name: node.name,
      protocol: node.protocol,
      outboundJson: node.outboundJson,
      sourceUrl: node.sourceUrl,
      rawLink: node.rawLink,
      updatedAt: node.updatedAt,
      delayMs: node.delayMs,
      delayTestAt: node.delayTestAt,
      delayStatus: node.delayStatus
    });
  }
  return copied;
}
