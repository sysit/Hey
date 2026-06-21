import { ProxyNode, SubscriptionGroup } from '../../core/Profile';
import { IconButton } from '../../components/IconButton';
import { ProxyNodeHandler } from '../servers/ServerCard';
import { AppColor, FontSz, Radius, Space } from '../../theme/Theme';
import { delayLevelColor, nodeDelayLevel, nodePresentation, NodePresentation } from './SubscriptionVisuals';

export type SubscriptionGroupHandler = (group: SubscriptionGroup) => void;

const EMPTY_NODE: ProxyNode = {
  id: '',
  name: '',
  protocol: '',
  outboundJson: '',
  sourceUrl: '',
  rawLink: '',
  updatedAt: 0,
  delayMs: 0,
  delayTestAt: 0,
  delayStatus: ''
};

const EMPTY_GROUP: SubscriptionGroup = {
  id: '',
  name: '',
  url: '',
  enabled: false,
  selectedNodeId: '',
  nodes: [],
  updatedAt: 0
};

@Component
export struct SubscriptionGroupListRow {
  group: SubscriptionGroup = EMPTY_GROUP;
  @Prop isSelected: boolean = false;
  @Prop summary: string = '';
  @Prop currentLabel: string = '';
  @Prop openLabel: string = '';
  @Prop onLabel: string = '';
  @Prop offLabel: string = '';
  @Prop deleteLabel: string = '';
  onSelect: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};
  onToggle: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};
  onDelete: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};

  build() {
    Column() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(this.group.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColor.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.summary)
            .fontSize(13)
            .fontColor(AppColor.textSecondary)
        }
        .layoutWeight(1)

        IconButton({
          icon: this.isSelected ? $r('app.media.ic_check') : $r('app.media.ic_chevron_right'),
          buttonSize: 42,
          iconSize: this.isSelected ? 22 : 28,
          iconColor: this.isSelected ? AppColor.onBrand : AppColor.textPrimary,
          buttonBackground: this.isSelected ? AppColor.brand : '#00000000',
          onAction: () => {
            this.onSelect(this.group);
          }
        })
        Toggle({ type: ToggleType.Switch, isOn: this.group.enabled })
          .selectedColor(AppColor.brand)
          .switchPointColor(AppColor.onBrand)
          .onChange((_isOn: boolean) => {
            this.onToggle(this.group);
          })
        IconButton({
          icon: $r('app.media.ic_delete'),
          buttonSize: 42,
          iconSize: 24,
          iconColor: AppColor.textPrimary,
          onAction: () => {
            this.onDelete(this.group);
          }
        })
      }
      .width('100%')
      .padding({ left: 24, right: 12, top: 14, bottom: 14 })
      Divider()
        .strokeWidth(1)
        .color(AppColor.divider)
        .margin({ left: 24 })
    }
    .width('100%')
    .backgroundColor(this.isSelected ? AppColor.brandTint : AppColor.surface)
  }
}

/**
 * 订阅详情页节点行：国旗 + 名称/协议 + 延迟信号点 + 当前项勾选。
 * 国旗与延迟着色由节点自身派生（纯逻辑），延迟文案因需本地化由外部传入。
 */
@Component
export struct SubscriptionNodeListRow {
  node: ProxyNode = EMPTY_NODE;
  @Prop isSelected: boolean = false;
  @Prop isBusy: boolean = false;
  @Prop delayText: string = '';
  @Prop showDivider: boolean = true;
  onSelect: ProxyNodeHandler = (_node: ProxyNode) => {};

  build() {
    Column() {
      Row({ space: 11 }) {
        Text(this.presentation().flag)
          .fontSize(19)

        Column({ space: 2 }) {
          Text(this.presentation().label)
            .fontSize(FontSz.callout)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isSelected ? AppColor.brand : AppColor.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.node.protocol.toUpperCase())
            .fontSize(FontSz.caption)
            .fontColor(AppColor.textTertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: 4 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.delayColor())
          Text(this.delayText)
            .fontSize(FontSz.footnote)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.delayColor())
        }
        .alignItems(VerticalAlign.Center)

        Image($r('app.media.ic_check'))
          .width(20)
          .height(20)
          .fillColor(AppColor.brand)
          .visibility(this.isSelected ? Visibility.Visible : Visibility.Hidden)
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .padding({ left: 14, right: 14, top: 11, bottom: 11 })

      if (this.showDivider) {
        Divider()
          .strokeWidth(0.5)
          .color(AppColor.divider)
          .margin({ left: Space.lg })
      }
    }
    .width('100%')
    .backgroundColor(this.isSelected ? AppColor.brandTint : Color.Transparent)
    .borderRadius(this.isSelected ? Radius.sm : 0)
    .enabled(!this.isBusy)
    .onClick(() => {
      this.onSelect(this.node);
    })
  }

  private presentation(): NodePresentation {
    return nodePresentation(this.node.name);
  }

  private delayColor(): ResourceColor {
    return delayLevelColor(nodeDelayLevel(this.node));
  }
}
