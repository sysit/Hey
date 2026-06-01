import { ProxyNode, SubscriptionGroup } from '../../core/Profile';
import { SubscriptionGroupListRow, SubscriptionNodeListRow } from './SubscriptionRows';

export interface SubscriptionGroupRowModel {
  group: SubscriptionGroup;
  isSelected: boolean;
  summary: string;
}

export interface SubscriptionNodeRowModel {
  node: ProxyNode;
  isSelected: boolean;
  delayText: string;
  delayColor: string;
}

export type SubscriptionUrlHandler = (value: string) => void;
export type SubscriptionActionHandler = () => void;
export type SubscriptionGroupActionHandler = (group: SubscriptionGroup) => void;
export type SubscriptionNodeActionHandler = (node: ProxyNode) => void;

@Component
export struct SubscriptionManagerPanel {
  title: string = '';
  summary: string = '';
  urlPlaceholder: string = '';
  urlValue: string = '';
  saveGroupLabel: string = '';
  updateLabel: string = '';
  message: string = '';
  isBusy: boolean = false;
  isUpdating: boolean = false;
  groupRows: Array<SubscriptionGroupRowModel> = [];
  nodeRows: Array<SubscriptionNodeRowModel> = [];
  currentLabel: string = '';
  openLabel: string = '';
  onLabel: string = '';
  offLabel: string = '';
  deleteLabel: string = '';
  selectedLabel: string = '';
  useLabel: string = '';
  onUrlChange: SubscriptionUrlHandler = (_value: string) => {};
  onSaveGroup: SubscriptionActionHandler = () => {};
  onUpdate: SubscriptionActionHandler = () => {};
  onSelectGroup: SubscriptionGroupActionHandler = (_group: SubscriptionGroup) => {};
  onToggleGroup: SubscriptionGroupActionHandler = (_group: SubscriptionGroup) => {};
  onDeleteGroup: SubscriptionGroupActionHandler = (_group: SubscriptionGroup) => {};
  onSelectNode: SubscriptionNodeActionHandler = (_node: ProxyNode) => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .layoutWeight(1)
        Text(this.summary)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .width('100%')

      TextArea({
        placeholder: this.urlPlaceholder,
        text: this.urlValue
      })
        .height(56)
        .fontSize(13)
        .fontColor('#111827')
        .placeholderColor('#9CA3AF')
        .backgroundColor('#F9FAFB')
        .borderRadius(6)
        .border({ width: 1, color: '#E5E7EB' })
        .padding(10)
        .onChange((value: string) => {
          this.onUrlChange(value);
        })

      Row({ space: 8 }) {
        Button(this.saveGroupLabel)
          .height(38)
          .width(116)
          .fontSize(14)
          .enabled(!this.isUpdating && !this.isBusy)
          .backgroundColor('#E5E7EB')
          .fontColor('#374151')
          .borderRadius(8)
          .onClick(() => {
            this.onSaveGroup();
          })
        Button(this.updateLabel)
          .height(38)
          .width(96)
          .fontSize(14)
          .enabled(!this.isUpdating && !this.isBusy)
          .backgroundColor('#1D4ED8')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.onUpdate();
          })
        Text(this.message)
          .fontSize(13)
          .fontColor('#374151')
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.groupRows.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.groupRows, (row: SubscriptionGroupRowModel) => {
            SubscriptionGroupListRow({
              group: row.group,
              isSelected: row.isSelected,
              summary: row.summary,
              currentLabel: this.currentLabel,
              openLabel: this.openLabel,
              onLabel: this.onLabel,
              offLabel: this.offLabel,
              deleteLabel: this.deleteLabel,
              onSelect: this.onSelectGroup,
              onToggle: this.onToggleGroup,
              onDelete: this.onDeleteGroup
            })
          }, (row: SubscriptionGroupRowModel) => row.group.id)
        }
        .width('100%')
      }

      if (this.nodeRows.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.nodeRows, (row: SubscriptionNodeRowModel) => {
            SubscriptionNodeListRow({
              node: row.node,
              isSelected: row.isSelected,
              isBusy: this.isBusy,
              delayText: row.delayText,
              delayColor: row.delayColor,
              selectedLabel: this.selectedLabel,
              useLabel: this.useLabel,
              onSelect: this.onSelectNode
            })
          }, (row: SubscriptionNodeRowModel) => row.node.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
