import { AppColor } from '../theme/Theme';

export type IconButtonHandler = () => void;

@Component
export struct IconButton {
  @Prop icon: Resource = $r('app.media.ic_more_vert');
  @Prop iconSize: number = 24;
  @Prop buttonSize: number = 44;
  @Prop iconColor: ResourceColor = AppColor.textPrimary;
  @Prop buttonBackground: ResourceColor = Color.Transparent;
  @Prop radius: number = 22;
  @Prop isEnabled: boolean = true;
  onAction: IconButtonHandler = () => {};

  build() {
    Button() {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .enabled(this.isEnabled)
    .backgroundColor(this.buttonBackground)
    .borderRadius(this.radius)
    .opacity(this.isEnabled ? 1 : 0.45)
    .onClick(() => {
      this.onAction();
    })
  }
}
