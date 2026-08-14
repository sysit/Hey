export type ConfigChangeHandler = (value: string) => void;
export type ConfigImportHandler = () => void;

@Component
export struct XrayConfigPanel {
  title: string = '';
  updatedAt: string = '';
  placeholder: string = '';
  outboundJson: string = '';
  validLabel: string = '';
  invalidLabel: string = '';
  validationOk: boolean = false;
  validationMessage: string = '';
  importLabel: string = '';
  isBusy: boolean = false;
  onConfigChange: ConfigChangeHandler = (_value: string) => {};
  onImport: ConfigImportHandler = () => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .layoutWeight(1)
        Text(this.updatedAt)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .width('100%')

      TextArea({
        placeholder: this.placeholder,
        text: this.outboundJson
      })
        .height(220)
        .fontSize(13)
        .fontColor('#111827')
        .placeholderColor('#9CA3AF')
        .backgroundColor('#F9FAFB')
        .borderRadius(6)
        .border({ width: 1, color: '#E5E7EB' })
        .padding(10)
        .onChange((value: string) => {
          this.onConfigChange(value);
        })

      Row({ space: 8 }) {
        Text(this.validationOk ? this.validLabel : this.invalidLabel)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.validationOk ? '#166534' : '#B42318')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.validationOk ? '#DCFCE7' : '#FEF3F2')
          .borderRadius(6)
        Text(this.validationMessage)
          .fontSize(13)
          .fontColor('#374151')
          .layoutWeight(1)
        Button(this.importLabel)
          .height(32)
          .width(76)
          .fontSize(13)
          .enabled(!this.isBusy)
          .backgroundColor('#E5E7EB')
          .fontColor('#374151')
          .borderRadius(6)
          .onClick(() => {
            this.onImport();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
