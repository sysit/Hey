import { AppColor, FontSz, Radius, Space } from '../theme/Theme';

@Component
export struct MetricTile {
  // @Prop：抽取的子组件展示成员必须用 @Prop，否则父 re-render 时不刷新（编译器对普通
  // 成员生成空的 updateStateVars()，时长/流量会冻结）。详见 arkui-child-component-prop-sync。
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column({ space: Space.xs }) {
      Text(this.label)
        .fontSize(FontSz.footnote)
        .fontColor(AppColor.textSecondary)
      Text(this.value)
        .fontSize(FontSz.callout)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColor.textPrimary)
    }
    .layoutWeight(1)
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColor.surfaceAlt)
    .borderRadius(Radius.sm)
  }
}

@Component
export struct FlagTile {
  @Prop label: string = '';
  @Prop active: boolean = false;

  build() {
    Row({ space: Space.sm }) {
      Circle()
        .width(8)
        .height(8)
        .fill(this.active ? AppColor.success : AppColor.textTertiary)
      Text(this.label)
        .fontSize(FontSz.footnote)
        .fontColor(AppColor.textSecondary)
    }
    .height(34)
    .padding({ left: Space.md, right: Space.md })
    .backgroundColor(AppColor.surfaceAlt)
    .borderRadius(Radius.sm)
  }
}
