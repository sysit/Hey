import { ProxyNode, SubscriptionGroup } from '../../core/Profile';
import { ProxyNodeHandler } from '../servers/ServerCard';

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
  isSelected: boolean = false;
  summary: string = '';
  currentLabel: string = '';
  openLabel: string = '';
  onLabel: string = '';
  offLabel: string = '';
  deleteLabel: string = '';
  onSelect: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};
  onToggle: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};
  onDelete: SubscriptionGroupHandler = (_group: SubscriptionGroup) => {};

  build() {
    Row({ space: 8 }) {
      Column({ space: 3 }) {
        Text(this.group.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.summary)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .layoutWeight(1)

      Button(this.isSelected ? this.currentLabel : this.openLabel)
        .height(32)
        .width(76)
        .fontSize(12)
        .backgroundColor(this.isSelected ? '#166534' : '#E5E7EB')
        .fontColor(this.isSelected ? '#FFFFFF' : '#374151')
        .borderRadius(6)
        .onClick(() => {
          this.onSelect(this.group);
        })
      Button(this.group.enabled ? this.onLabel : this.offLabel)
        .height(32)
        .width(58)
        .fontSize(12)
        .backgroundColor(this.group.enabled ? '#EEF2FF' : '#F3F4F6')
        .fontColor(this.group.enabled ? '#3730A3' : '#6B7280')
        .borderRadius(6)
        .onClick(() => {
          this.onToggle(this.group);
        })
      Button(this.deleteLabel)
        .height(32)
        .width(54)
        .fontSize(12)
        .backgroundColor('#FEF3F2')
        .fontColor('#B42318')
        .borderRadius(6)
        .onClick(() => {
          this.onDelete(this.group);
        })
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.isSelected ? '#F0FDF4' : '#F9FAFB')
    .borderRadius(6)
  }
}

@Component
export struct SubscriptionNodeListRow {
  node: ProxyNode = EMPTY_NODE;
  isSelected: boolean = false;
  isBusy: boolean = false;
  delayText: string = '';
  delayColor: string = '#6B7280';
  selectedLabel: string = '';
  useLabel: string = '';
  onSelect: ProxyNodeHandler = (_node: ProxyNode) => {};

  build() {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text(this.node.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.node.protocol.toUpperCase())
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .layoutWeight(1)

      Text(this.delayText)
        .fontSize(12)
        .fontColor(this.delayColor)
        .width(84)
        .textAlign(TextAlign.Center)

      Button(this.isSelected ? this.selectedLabel : this.useLabel)
        .height(34)
        .width(86)
        .fontSize(13)
        .enabled(!this.isBusy)
        .backgroundColor(this.isSelected ? '#166534' : '#E5E7EB')
        .fontColor(this.isSelected ? '#FFFFFF' : '#374151')
        .borderRadius(6)
        .onClick(() => {
          this.onSelect(this.node);
        })
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.isSelected ? '#F0FDF4' : '#F9FAFB')
    .borderRadius(6)
  }
}
