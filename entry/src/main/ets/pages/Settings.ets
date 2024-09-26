
@Component
@Preview
export struct Settings {
  @StorageLink("displayConfThreshold") displayConfThreshold: number = 0.25;
  @StorageLink("uploadImageQuality") uploadImageQuality: number = 0.98;

  build() {
    Scroll() {
      Column() {
        this.TitleBar()

        Blank().height(30)

        SettingItem({
          icon: $r('app.media.ic_confidence'),
          title: '置信度阈值',
          value: this.displayConfThreshold.toFixed(2),
          valueToChange: this.displayConfThreshold
        })

        SettingItem({
          icon: $r('app.media.ic_image'),
          title: '上传图片质量',
          value: `${(this.uploadImageQuality * 100).toFixed(0)}%`,
          valueToChange: this.uploadImageQuality
        })
      }
      .padding({
        top: 12,
        right: 16,
        bottom: 12,
        left: 16
      })

    }
    .backgroundColor('#F1F3F5')
    .align(Alignment.TopStart)
    .constraintSize({ minHeight: '100%' })
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.TopStart)
  }

  @Builder
  TitleBar() {
    Row() {
      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
  }
}

@Component
export struct SettingItem {
  @Prop icon: Resource;
  @Prop title: string;
  @Prop value: string;
  @Link valueToChange: number;

  build() {
    Column() {
      Row() {
        Image(this.icon)
          .width(24)
          .height(24)
          .margin({ right: 12 })
        Text(this.title)
          .fontSize(16)
          .fontColor(Color.Black)
        Blank()
        Text(this.value)
          .fontSize(16)
          .fontColor(Color.Blue)
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)

      Slider({
        value: parseFloat(this.value),
        min: 0,
        max: 1,
        step: 0.01,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .onChange((value: number) => {
          this.valueToChange = value
        })
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .padding(16)
    .margin({ bottom: 16 })
  }
}