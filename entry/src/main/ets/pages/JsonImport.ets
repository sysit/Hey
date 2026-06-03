import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { DEFAULT_LANGUAGE, translate } from '../core/I18n';
import { AppLanguage } from '../core/Profile';
import { NODES_CONTROLLER } from '../features/nodes/NodesController';
import { SETTINGS_CONTROLLER } from '../features/settings/SettingsController';
import { SHARED_RUNTIME_CONTROLLER } from '../features/runtime/RuntimeController';
import { SubscriptionStore } from '../storage/SubscriptionStore';
import { PageHeader } from '../shell/PageHeader';

@Entry
@Component
struct JsonImportPage {
  @State private language: AppLanguage = DEFAULT_LANGUAGE;
  @State private outboundJson: string = '';
  @State private validationMessage: string = '';
  @State private validationOk: boolean = false;
  @State private isBusy: boolean = false;
  @State private lastError: string = '';
  @State private isPressed: boolean = false;

  aboutToAppear(): void {
    this.loadState();
  }

  build() {
    Column() {
      PageHeader({
        title: translate(this.language, 'screen.jsonImport.title'),
        showBack: true
      })

      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column({ space: 16 }) {
            // 输入卡片
            Column({ space: 12 }) {
              Row() {
                Text('Outbound JSON 配置')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111827')
                
                Blank()
                
                // 粘贴与清空操作按钮
                Row({ space: 8 }) {
                  Button('粘贴')
                    .fontSize(12)
                    .fontColor('#374151')
                    .backgroundColor('#E5E7EB')
                    .height(28)
                    .padding({ left: 10, right: 10 })
                    .borderRadius(6)
                    .onClick(() => {
                      this.pasteFromClipboard();
                    })

                  if (this.outboundJson.length > 0) {
                    Button('清空')
                      .fontSize(12)
                      .fontColor('#EF4444')
                      .backgroundColor('#FEE2E2')
                      .height(28)
                      .padding({ left: 10, right: 10 })
                      .borderRadius(6)
                      .onClick(() => {
                        this.outboundJson = '';
                        this.validateConfig();
                      })
                  }
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              TextArea({
                placeholder: '请粘贴完整的 Xray outbound JSON 配置，例如：\n{\n  "protocol": "vless",\n  "settings": { ... }\n}',
                text: this.outboundJson
              })
                .height(260)
                .fontSize(13)
                .fontColor('#111827')
                .fontFamily('monospace')
                .backgroundColor('#F9FAFB')
                .borderRadius(10)
                .padding(12)
                .onChange((value: string) => {
                  this.outboundJson = value;
                  this.validateConfig();
                })

              Text('注意：填入的配置必须符合标准的 Xray 出站协议格式，需包含 protocol 和 settings 核心字段。')
                .fontSize(12)
                .fontColor('#9CA3AF')
                .width('100%')
                .lineHeight(16)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })

            // 校验结果指示板
            if (this.outboundJson.trim().length > 0) {
              Column({ space: 8 }) {
                Row({ space: 6 }) {
                  Column()
                    .width(6)
                    .height(6)
                    .borderRadius(3)
                    .backgroundColor(this.validationOk ? '#10B981' : '#EF4444')
                  
                  Text(this.validationOk ? '配置格式有效' : '配置格式无效')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.validationOk ? '#047857' : '#B91C1C')
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Text(this.validationMessage)
                  .fontSize(12)
                  .fontColor(this.validationOk ? '#065F46' : '#991B1B')
                  .width('100%')
                  .lineHeight(16)
              }
              .width('100%')
              .padding(14)
              .backgroundColor(this.validationOk ? '#ECFDF5' : '#FEF2F2')
              .borderRadius(12)
              .borderWidth(1)
              .borderColor(this.validationOk ? '#A7F3D0' : '#FCA5A5')
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
              Text('导入此 JSON 节点')
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
            this.importJsonNode();
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

  private isSaveEnabled(): boolean {
    return this.outboundJson.trim().length > 0 && this.validationOk && !this.isBusy;
  }

  private async loadState(): Promise<void> {
    const context = getContext(this) as common.Context;
    this.language = (await SETTINGS_CONTROLLER.load(context)).language;
    this.validateConfig();
  }

  private validateConfig(): void {
    const value = this.outboundJson.trim();
    if (value.length === 0) {
      this.validationOk = false;
      this.validationMessage = '';
      return;
    }
    const validation = NODES_CONTROLLER.validateConfig(value, this.language);
    this.validationOk = validation.valid;
    this.validationMessage = validation.message;
  }

  private async importJsonNode(): Promise<void> {
    const value = this.outboundJson.trim();
    if (value.length === 0 || !this.validationOk) {
      return;
    }

    this.isBusy = true;
    try {
      const context = getContext(this) as common.Context;
      const validation = NODES_CONTROLLER.validateConfig(value, this.language);
      if (!validation.valid) {
        this.lastError = validation.message;
        return;
      }
      
      const normalizedJson = validation.normalizedJson;
      // 提取 JSON 中 tag 字段作为节点名，若无则使用默认名称
      let nodeName = 'JSON导入';
      try {
        const obj = JSON.parse(normalizedJson) as Record<string, Object>;
        if (obj.tag && typeof obj.tag === 'string' && obj.tag.trim().length > 0) {
          nodeName = obj.tag.trim();
        }
      } catch (err) {
        // ignore
      }

      const savedProfile = await NODES_CONTROLLER.saveProfile(context, normalizedJson, this.language);
      if (savedProfile.profile === null) {
        this.lastError = savedProfile.lastError;
        return;
      }

      await SubscriptionStore.addManualNode(context, nodeName, normalizedJson);
      SHARED_RUNTIME_CONTROLLER.appendLog('自定义 JSON 节点导入成功');
      promptAction.showToast({ message: '节点导入成功' });
      router.back();
    } catch (error) {
      this.lastError = '导入失败：' + JSON.stringify(error);
    } finally {
      this.isBusy = false;
    }
  }

  private async pasteFromClipboard() {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      if (systemPasteboard.hasDataSync()) {
        const pasteData = await systemPasteboard.getData();
        const text = pasteData.getPrimaryText();
        if (text && text.trim().length > 0) {
          this.outboundJson = text.trim();
          this.validateConfig();
          promptAction.showToast({ message: '已粘贴 JSON 配置' });
        } else {
          promptAction.showToast({ message: '剪贴板未发现有效文本' });
        }
      } else {
        promptAction.showToast({ message: '剪贴板为空' });
      }
    } catch (error) {
      promptAction.showToast({ message: '无法读取剪贴板' });
    }
  }
}
