// // 新增绘制方法
// async drawDefectsOnImage() {
//   if (!this.resultPicPixelMap || !this.detectionResult) {
//     console.error("PixelMap or detection result is not available");
//     return;
//   }
//
//   // 获取 PixelMap 的图像信息
//   const imageInfo = await this.resultPicPixelMap.getImageInfo();
//   const imgWidth = imageInfo.size.width;
//   const imgHeight = imageInfo.size.height;
//
//   // 获取Canvas的渲染上下文
//   const context = new CanvasRenderingContext2D(new RenderingContextSettings(true));
//
//   // 将 PixelMap 绘制到 Canvas 上
//   try {
//     context.drawImage(this.resultPicPixelMap, 0, 0, imgWidth, imgHeight);
//   } catch (e) {
//     console.error("Error drawing PixelMap:", e);
//     return;
//   }
//
//   // 设置绘制样式
//   context.strokeStyle = '#FF0000'; // 红色边框
//   context.lineWidth = 2;           // 边框宽度
//
//   // 遍历所有检测到的缺陷并绘制边界框
//   this.detectionResult.results.forEach((defect: Defect) => {
//     context.beginPath();
//     context.rect(defect.x1, defect.y1, defect.x2 - defect.x1, defect.y2 - defect.y1);
//     context.stroke();
//   });
//
//   // 使用 getPixelMap 截取整个区域并更新带缺陷框的图片
//   try {
//     const updatedPixelMap = context.getPixelMap(0, 0, imgWidth, imgHeight);
//     if (updatedPixelMap) {
//       this.resultPicPixelMap = updatedPixelMap; // 更新 PixelMap
//     } else {
//       console.error("Failed to get updated PixelMap");
//     }
//   } catch (e) {
//     console.error("Error getting updated PixelMap:", e);
//   }
// }