import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';
import { DEFAULT_LANGUAGE, translate } from '../core/I18n';
import { AppLanguage } from '../core/Profile';
import { NODES_CONTROLLER } from '../features/nodes/NodesController';
import { SETTINGS_CONTROLLER } from '../features/settings/SettingsController';
import { SHARED_RUNTIME_CONTROLLER } from '../features/runtime/RuntimeController';
import { SubscriptionStore } from '../storage/SubscriptionStore';
import { PageHeader } from '../shell/PageHeader';

interface FormVlessUser {
  id: string;
  encryption: string;
}

interface FormVlessServer {
  address: string;
  port: number;
  users: Array<FormVlessUser>;
}

interface FormVlessSettings {
  vnext: Array<FormVlessServer>;
}

interface FormVmessUser {
  id: string;
  alterId: number;
  security: string;
}

interface FormVmessServer {
  address: string;
  port: number;
  users: Array<FormVmessUser>;
}

interface FormVmessSettings {
  vnext: Array<FormVmessServer>;
}

interface FormTrojanServer {
  address: string;
  port: number;
  password: string;
}

interface FormTrojanSettings {
  servers: Array<FormTrojanServer>;
}

interface FormShadowsocksServer {
  address: string;
  port: number;
  method: string;
  password: string;
}

interface FormShadowsocksSettings {
  servers: Array<FormShadowsocksServer>;
}

interface FormGenericUser {
  user: string;
  pass: string;
}

interface FormGenericServer {
  address: string;
  port: number;
  users?: Array<FormGenericUser>;
}

interface FormServerSettings {
  servers: Array<FormGenericServer>;
}

interface FormWsHeaders {
  Host: string;
}

interface FormWsSettings {
  path: string;
  headers: FormWsHeaders;
}

interface FormGrpcSettings {
  serviceName: string;
  authority: string;
}

interface FormHttpSettings {
  path: string;
  host: Array<string>;
}

interface FormStreamSettings {
  network: string;
  security?: string;
  wsSettings?: FormWsSettings;
  grpcSettings?: FormGrpcSettings;
  httpSettings?: FormHttpSettings;
}

type FormOutboundSettings = FormVlessSettings | FormVmessSettings | FormTrojanSettings | FormShadowsocksSettings | FormServerSettings;

interface FormOutbound {
  protocol: string;
  tag: string;
  settings?: FormOutboundSettings;
  streamSettings?: FormStreamSettings;
}

@Entry
@Component
struct NodeEditPage {
  @State private language: AppLanguage = DEFAULT_LANGUAGE;
  @State private protocol: string = 'vless';
  @State private nodeName: string = '';
  @State private serverHost: string = '';
  @State private serverPort: string = '443';
  @State private userIdOrPassword: string = '';
  @State private proxyUser: string = '';
  @State private proxyPass: string = '';
  @State private securityOrMethod: string = 'none';
  @State private vmessAlterId: string = '0';
  @State private transportType: string = 'tcp';
  @State private transportHost: string = '';
  @State private transportPath: string = '';
  @State private tlsSecurity: string = '';
  @State private isBusy: boolean = false;
  @State private lastError: string = '';
  @State private isPressed: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    this.protocol = (params?.protocol as string) ?? 'vless';
    this.applyProtocolDefaults(this.protocol);
    this.loadState();
  }

  build() {
    Column() {
      PageHeader({
        title: `配置 ${this.protocol.toUpperCase()} 节点`,
        showBack: true
      })

      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column({ space: 16 }) {
            // 基本参数卡片
            Column({ space: 14 }) {
              this.CardSectionTitle('基础配置信息')
              
              this.EditorRow('节点名称', this.nodeName, '例如：主力香港节点', (value: string) => {
                this.nodeName = value;
              })
              this.EditorRow('服务器地址', this.serverHost, 'IP 地址或域名', (value: string) => {
                this.serverHost = value;
              })
              this.EditorRow('端口', this.serverPort, '端口（1-65535）', (value: string) => {
                this.serverPort = value;
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })

            // 核心认证卡片
            Column({ space: 14 }) {
              this.CardSectionTitle('认证与加密')

              if (this.protocol === 'vless' || this.protocol === 'vmess') {
                this.EditorRow('用户 ID (UUID)', this.userIdOrPassword, '36 位用户 UUID', (value: string) => {
                  this.userIdOrPassword = value;
                })
              } else if (this.protocol === 'trojan' || this.protocol === 'ss') {
                this.EditorRow(this.protocol === 'trojan' ? '连接密码' : '加密密码', this.userIdOrPassword, '连接密码', (value: string) => {
                  this.userIdOrPassword = value;
                })
              }

              if (this.protocol === 'socks' || this.protocol === 'http') {
                this.EditorRow('用户名 (可选)', this.proxyUser, '代理用户名', (value: string) => {
                  this.proxyUser = value;
                })
                this.EditorRow('密码 (可选)', this.proxyPass, '代理连接密码', (value: string) => {
                  this.proxyPass = value;
                })
              }

              if (this.protocol === 'vless') {
                this.EditorRow('加密算法 (encryption)', this.securityOrMethod, '默认 none', (value: string) => {
                  this.securityOrMethod = value;
                })
              } else if (this.protocol === 'vmess') {
                this.EditorRow('加密安全性 (security)', this.securityOrMethod, '默认 auto', (value: string) => {
                  this.securityOrMethod = value;
                })
                this.EditorRow('额外 ID (alterId)', this.vmessAlterId, '一般设为 0', (value: string) => {
                  this.vmessAlterId = value;
                })
              } else if (this.protocol === 'ss') {
                this.EditorRow('加密方法 (method)', this.securityOrMethod, '例如 aes-128-gcm', (value: string) => {
                  this.securityOrMethod = value;
                })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })

            // 传输与混淆设置 (VLESS, VMESS, Trojan)
            if (this.protocol === 'vless' || this.protocol === 'vmess' || this.protocol === 'trojan') {
              Column({ space: 14 }) {
                this.CardSectionTitle('传输与混淆设置')

                this.EditorRow('传输协议 (network)', this.transportType, 'tcp / ws / grpc / h2', (value: string) => {
                  this.transportType = value;
                })
                this.EditorRow('伪装域名 (host)', this.transportHost, '可选域名设置', (value: string) => {
                  this.transportHost = value;
                })
                this.EditorRow('伪装路径 (path)', this.transportPath, '可选路径设置', (value: string) => {
                  this.transportPath = value;
                })
                this.EditorRow('传输安全 (security)', this.tlsSecurity, 'tls / reality / 空', (value: string) => {
                  this.tlsSecurity = value;
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
            }

            if (this.lastError.length > 0) {
              Text(this.lastError)
                .fontSize(12)
                .fontColor('#B42318')
                .width('100%')
                .padding(10)
                .backgroundColor('#FEF3F2')
                .borderRadius(6)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 100 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)

        // 底部保存按钮
        Column() {
          Button() {
            Row() {
              if (this.isBusy) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#FFFFFF')
                  .margin({ right: 8 })
              }
              Text('保存节点配置')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isSaveEnabled() ? '#FFFFFF' : '#9CA3AF')
            }
          }
          .width('100%')
          .height(50)
          .borderRadius(12)
          .enabled(this.isSaveEnabled())
          .opacity(this.isSaveEnabled() ? 1.0 : 0.65)
          .linearGradient(this.isSaveEnabled() ? {
            angle: 90,
            colors: [['#FF8F3D', 0.0], ['#F97910', 1.0]]
          } : {
            angle: 90,
            colors: [['#E5E7EB', 0.0], ['#E5E7EB', 1.0]]
          })
          .shadow(this.isSaveEnabled() ? { radius: 10, color: '#30F97910', offsetX: 0, offsetY: 4 } : undefined)
          .scale({ x: this.isPressed ? 0.97 : 1.0, y: this.isPressed ? 0.97 : 1.0 })
          .animation({ duration: 150, curve: Curve.EaseOut })
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.isPressed = true;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.isPressed = false;
            }
          })
          .onClick(() => {
            this.saveManualNode();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        .backgroundColor('#C0F3F4F6')
        .backgroundBlurStyle(BlurStyle.Thin)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  private CardSectionTitle(title: string) {
    Row({ space: 8 }) {
      Column()
        .width(4)
        .height(16)
        .backgroundColor('#F97910')
        .borderRadius(2)
      
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 4 })
  }

  @Builder
  private EditorRow(label: string, value: string, placeholder: string, onChange: (value: string) => void) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor('#4B5563')
        .width('100%')
      TextInput({ text: value, placeholder: placeholder })
        .height(42)
        .fontSize(13)
        .backgroundColor('#F3F4F6')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((next: string) => {
          onChange(next);
        })
    }
    .width('100%')
  }

  private isSaveEnabled(): boolean {
    return this.serverHost.trim().length > 0 && this.serverPort.trim().length > 0 && !this.isBusy;
  }

  private async loadState(): Promise<void> {
    const context = getContext(this) as common.Context;
    this.language = (await SETTINGS_CONTROLLER.load(context)).language;
  }

  private async saveManualNode(): Promise<void> {
    const host = this.serverHost.trim();
    const port = Number(this.serverPort.trim());
    if (host.length === 0 || Number.isNaN(port) || port < 1 || port > 65535) {
      this.lastError = '请填写有效的服务器和端口';
      return;
    }

    this.isBusy = true;
    try {
      const outbound: FormOutbound = {
        protocol: this.protocol === 'ss' ? 'shadowsocks' : this.protocol,
        tag: this.nodeName.trim().length > 0 ? this.nodeName.trim() : 'proxy'
      };

      if (this.protocol === 'vless') {
        const user: FormVlessUser = {
          id: this.userIdOrPassword.trim(),
          encryption: this.valueOr(this.securityOrMethod, 'none')
        };
        const server: FormVlessServer = {
          address: host,
          port: port,
          users: [user]
        };
        outbound.settings = {
          vnext: [server]
        } as FormVlessSettings;
      } else if (this.protocol === 'vmess') {
        const user: FormVmessUser = {
          id: this.userIdOrPassword.trim(),
          alterId: this.numberOr(this.vmessAlterId, 0),
          security: this.valueOr(this.securityOrMethod, 'auto')
        };
        const server: FormVmessServer = {
          address: host,
          port: port,
          users: [user]
        };
        outbound.settings = {
          vnext: [server]
        } as FormVmessSettings;
      } else if (this.protocol === 'trojan') {
        const server: FormTrojanServer = {
          address: host,
          port: port,
          password: this.userIdOrPassword.trim()
        };
        outbound.settings = {
          servers: [server]
        } as FormTrojanSettings;
      } else if (this.protocol === 'ss') {
        const server: FormShadowsocksServer = {
          address: host,
          port: port,
          method: this.valueOr(this.securityOrMethod, 'aes-128-gcm'),
          password: this.userIdOrPassword.trim()
        };
        outbound.settings = {
          servers: [server]
        } as FormShadowsocksSettings;
      } else if (this.protocol === 'socks' || this.protocol === 'http') {
        const server: FormGenericServer = {
          address: host,
          port: port
        };
        const user = this.proxyUser.trim();
        const pass = this.proxyPass.trim();
        if (user.length > 0 || pass.length > 0) {
          const account: FormGenericUser = {
            user: user,
            pass: pass
          };
          server.users = [account];
        }
        outbound.settings = {
          servers: [server]
        } as FormServerSettings;
      }

      if (this.protocol === 'vless' || this.protocol === 'vmess' || this.protocol === 'trojan') {
        const network = this.valueOr(this.transportType, 'tcp').toLowerCase();
        const streamSettings: FormStreamSettings = {
          network: network
        };
        const security = this.tlsSecurity.trim().toLowerCase();
        if (security === 'tls' || security === 'reality') {
          streamSettings.security = security;
        }
        if (network === 'ws') {
          const wsSettings: FormWsSettings = {
            path: this.valueOr(this.transportPath, '/'),
            headers: {
              Host: this.transportHost.trim()
            }
          };
          streamSettings.wsSettings = wsSettings;
        } else if (network === 'grpc') {
          const grpcSettings: FormGrpcSettings = {
            serviceName: this.transportPath.trim(),
            authority: this.transportHost.trim()
          };
          streamSettings.grpcSettings = grpcSettings;
        } else if (network === 'h2') {
          const hosts = new Array<string>();
          const transportHost = this.transportHost.trim();
          if (transportHost.length > 0) {
            hosts.push(transportHost);
          }
          const httpSettings: FormHttpSettings = {
            path: this.valueOr(this.transportPath, '/'),
            host: hosts
          };
          streamSettings.httpSettings = httpSettings;
        }
        outbound.streamSettings = streamSettings;
      }

      const outboundJson = JSON.stringify(outbound, null, 2);
      const context = getContext(this) as common.Context;
      
      const validation = NODES_CONTROLLER.validateConfig(outboundJson, this.language);
      if (!validation.valid) {
        this.lastError = validation.message;
        return;
      }

      const saved = await NODES_CONTROLLER.saveProfile(context, validation.normalizedJson, this.language);
      if (saved.profile === null) {
        this.lastError = saved.lastError;
        return;
      }

      await SubscriptionStore.addManualNode(context, this.nodeName, validation.normalizedJson);
      promptAction.showToast({ message: '节点保存成功' });
      router.back();
    } catch (error) {
      this.lastError = '保存失败：' + JSON.stringify(error);
    } finally {
      this.isBusy = false;
    }
  }

  private valueOr(value: string, fallback: string): string {
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : fallback;
  }

  private numberOr(value: string, fallback: number): number {
    const parsed = Number(value.trim());
    if (Number.isNaN(parsed)) {
      return fallback;
    }
    return Math.floor(parsed);
  }

  private applyProtocolDefaults(protocol: string): void {
    if (protocol === 'vless') {
      this.serverPort = '443';
      this.securityOrMethod = 'none';
      this.transportType = 'tcp';
      this.tlsSecurity = '';
    } else if (protocol === 'vmess') {
      this.serverPort = '443';
      this.securityOrMethod = 'auto';
      this.vmessAlterId = '0';
      this.transportType = 'tcp';
      this.tlsSecurity = '';
    } else if (protocol === 'trojan') {
      this.serverPort = '443';
      this.transportType = 'tcp';
      this.tlsSecurity = 'tls';
    } else if (protocol === 'ss') {
      this.serverPort = '8388';
      this.securityOrMethod = 'aes-128-gcm';
      this.transportType = 'tcp';
      this.tlsSecurity = '';
    } else if (protocol === 'socks') {
      this.serverPort = '1080';
      this.transportType = 'tcp';
      this.tlsSecurity = '';
    } else if (protocol === 'http') {
      this.serverPort = '8080';
      this.transportType = 'tcp';
      this.tlsSecurity = '';
    }
  }
}
