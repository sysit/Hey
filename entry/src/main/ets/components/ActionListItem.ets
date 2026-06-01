export type ActionListItemHandler = (title: string) => void;

@Component
export struct ActionListItem {
  title: string = '';
  detail: string = '';
  actionLabel: string = '';
  onAction: ActionListItemHandler = (_title: string) => {};

  build() {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Text(this.detail)
          .fontSize(12)
          .fontColor('#6B7280')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      Button(this.actionLabel)
        .height(32)
        .width(68)
        .fontSize(12)
        .backgroundColor('#E5E7EB')
        .fontColor('#374151')
        .borderRadius(6)
        .onClick(() => {
          this.onAction(this.title);
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
