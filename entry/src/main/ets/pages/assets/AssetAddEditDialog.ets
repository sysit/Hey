import { AppLanguage } from '../../core/Profile';
import { translate } from '../../core/I18n';

@Component
export struct AssetAddEditDialog {
  @Prop language: AppLanguage;
  @Prop title: string;
  @Prop initialName: string;
  @Prop initialUrl: string;
  
  @State inputName: string = '';
  @State inputUrl: string = '';

  onCancel: () => void = () => {};
  onConfirm: (name: string, url: string) => void = (name, url) => {};

  aboutToAppear() {
    this.inputName = this.initialName;
    this.inputUrl = this.initialUrl;
  }

  private t(key: string): string {
    return translate(this.language, key);
  }

  build() {
    Stack() {
      // 遮罩层
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.45)')
        .onClick(() => {
          this.onCancel();
        })

      // 弹窗主体
      Column({ space: 16 }) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')

        Column({ space: 10 }) {
          Text(this.t('assets.urlName'))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4B5563')
            .alignSelf(ItemAlign.Start)
          TextInput({ text: this.inputName, placeholder: 'e.g. custom_geo' })
            .height(42)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .onChange((val) => this.inputName = val)

          Text(this.t('assets.urlAddress'))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4B5563')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 4 })
          TextInput({ text: this.inputUrl, placeholder: 'https://...' })
            .height(42)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .enabled(!this.inputUrl.startsWith('local://'))
            .onChange((val) => this.inputUrl = val)
        }

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor('#E5E7EB')
            .fontColor('#374151')
            .height(38)
            .borderRadius(8)
            .onClick(() => {
              this.onCancel();
            })

          Button('确认')
            .layoutWeight(1)
            .backgroundColor('#007DFF')
            .fontColor('#FFFFFF')
            .height(38)
            .borderRadius(8)
            .onClick(() => {
              this.onConfirm(this.inputName, this.inputUrl);
            })
        }
      }
      .width('85%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .height('100%')
  }
}
