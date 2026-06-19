import { ProxyNode } from './Profile';
import { normalizeConfigInput } from './XrayConfig';

interface SubscriptionNodeIdentity {
  remarks: string;
  server: string;
  serverPort: string;
  password: string;
}

export function resolveRetainedSelectedNodeId(existingNodes: Array<ProxyNode>, nextNodes: Array<ProxyNode>, selectedNodeId: string): string {
  if (nextNodes.length === 0) {
    return '';
  }
  if (findNodeById(nextNodes, selectedNodeId) !== null) {
    return selectedNodeId;
  }

  const target = findNodeById(existingNodes, selectedNodeId);
  if (target === null) {
    return nextNodes[0].id;
  }

  const matched = findMatchedSubscriptionNode(nextNodes, target);
  return matched !== null ? matched.id : nextNodes[0].id;
}

export function findMatchedSubscriptionNode(nodes: Array<ProxyNode>, target: ProxyNode): ProxyNode | null {
  const targetIdentity = nodeIdentity(target);
  const identities = new Array<SubscriptionNodeIdentity>();
  for (let index = 0; index < nodes.length; index++) {
    identities.push(nodeIdentity(nodes[index]));
  }

  const fullMatch = findByPredicate(nodes, identities, (identity: SubscriptionNodeIdentity): boolean => {
    return sameText(identity.remarks, targetIdentity.remarks) &&
      sameText(identity.server, targetIdentity.server) &&
      sameText(identity.serverPort, targetIdentity.serverPort) &&
      sameText(identity.password, targetIdentity.password);
  });
  if (fullMatch !== null) {
    return fullMatch;
  }

  const remarksMatch = findByPredicate(nodes, identities, (identity: SubscriptionNodeIdentity): boolean => {
    return sameText(identity.remarks, targetIdentity.remarks);
  });
  if (remarksMatch !== null) {
    return remarksMatch;
  }

  const serverPasswordMatch = findByPredicate(nodes, identities, (identity: SubscriptionNodeIdentity): boolean => {
    return sameText(identity.server, targetIdentity.server) &&
      sameText(identity.serverPort, targetIdentity.serverPort) &&
      sameText(identity.password, targetIdentity.password);
  });
  if (serverPasswordMatch !== null) {
    return serverPasswordMatch;
  }

  const serverPortMatch = findByPredicate(nodes, identities, (identity: SubscriptionNodeIdentity): boolean => {
    return sameText(identity.server, targetIdentity.server) &&
      sameText(identity.serverPort, targetIdentity.serverPort);
  });
  if (serverPortMatch !== null) {
    return serverPortMatch;
  }

  return findByPredicate(nodes, identities, (identity: SubscriptionNodeIdentity): boolean => {
    return sameText(identity.server, targetIdentity.server);
  });
}

function findByPredicate(
  nodes: Array<ProxyNode>,
  identities: Array<SubscriptionNodeIdentity>,
  predicate: (identity: SubscriptionNodeIdentity) => boolean
): ProxyNode | null {
  for (let index = 0; index < identities.length; index++) {
    if (predicate(identities[index])) {
      return nodes[index];
    }
  }
  return null;
}

function findNodeById(nodes: Array<ProxyNode>, nodeId: string): ProxyNode | null {
  if (nodeId.length === 0) {
    return null;
  }
  for (let index = 0; index < nodes.length; index++) {
    if (nodes[index].id === nodeId) {
      return nodes[index];
    }
  }
  return null;
}

function nodeIdentity(node: ProxyNode): SubscriptionNodeIdentity {
  const identity: SubscriptionNodeIdentity = {
    remarks: node.name,
    server: '',
    serverPort: '',
    password: ''
  };

  const validation = normalizeConfigInput(node.outboundJson, node.configType);
  const configJson = validation.valid ? validation.normalizedJson : node.outboundJson;
  try {
    const outbound = JSON.parse(configJson) as Record<string, Object>;
    const protocol = stringValue(outbound['protocol']).toLowerCase();
    const settings = objectValue(outbound['settings']);
    if (settings === null) {
      return identity;
    }

    if (protocol === 'vless' || protocol === 'vmess') {
      fillVnextIdentity(identity, settings);
    } else if (protocol === 'wireguard') {
      fillWireguardIdentity(identity, settings);
    } else {
      fillServerIdentity(identity, settings);
    }
  } catch (_error) {
    return identity;
  }

  return identity;
}

function fillVnextIdentity(identity: SubscriptionNodeIdentity, settings: Record<string, Object>): void {
  const server = firstRecord(settings['vnext']);
  if (server === null) {
    return;
  }
  identity.server = stringValue(server['address']);
  identity.serverPort = stringValue(server['port']);
  const user = firstRecord(server['users']);
  if (user !== null) {
    identity.password = stringValue(user['id']);
  }
}

function fillServerIdentity(identity: SubscriptionNodeIdentity, settings: Record<string, Object>): void {
  const server = firstRecord(settings['servers']);
  if (server === null) {
    return;
  }
  identity.server = stringValue(server['address']);
  identity.serverPort = stringValue(server['port']);
  identity.password = stringValue(server['password']);
  if (identity.password.length === 0) {
    const user = firstRecord(server['users']);
    if (user !== null) {
      identity.password = `${stringValue(user['user'])}:${stringValue(user['pass'])}`;
    }
  }
}

function fillWireguardIdentity(identity: SubscriptionNodeIdentity, settings: Record<string, Object>): void {
  const peer = firstRecord(settings['peers']);
  if (peer !== null) {
    const endpoint = stringValue(peer['endpoint']);
    identity.server = endpointHost(endpoint);
    identity.serverPort = endpointPort(endpoint);
  }
  identity.password = stringValue(settings['secretKey']);
}

function firstRecord(value: Object | undefined): Record<string, Object> | null {
  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }
  const values = value as Array<Object>;
  const first: Object = values[0];
  return objectValue(first);
}

function objectValue(value: Object | undefined): Record<string, Object> | null {
  if (value === undefined || value === null || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, Object>;
}

function stringValue(value: Object | undefined): string {
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`;
  }
  return '';
}

function sameText(left: string, right: string): boolean {
  const normalizedLeft = left.trim();
  const normalizedRight = right.trim();
  return normalizedLeft.length > 0 &&
    normalizedRight.length > 0 &&
    normalizedLeft.toLowerCase() === normalizedRight.toLowerCase();
}

function endpointHost(endpoint: string): string {
  if (endpoint.startsWith('[')) {
    const endIndex = endpoint.indexOf(']');
    if (endIndex > 0) {
      return endpoint.substring(1, endIndex);
    }
  }
  const portIndex = endpoint.lastIndexOf(':');
  return portIndex > 0 ? endpoint.substring(0, portIndex) : endpoint;
}

function endpointPort(endpoint: string): string {
  if (endpoint.startsWith('[')) {
    const endIndex = endpoint.indexOf(']');
    if (endIndex > 0 && endpoint.substring(endIndex + 1, endIndex + 2) === ':') {
      return endpoint.substring(endIndex + 2);
    }
    return '';
  }
  const portIndex = endpoint.lastIndexOf(':');
  return portIndex > 0 ? endpoint.substring(portIndex + 1) : '';
}
