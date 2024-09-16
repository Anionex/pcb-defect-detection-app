export class DefectColorMapper {
  colorMap: Map<string, string> = new Map([
    ['Mouse_bite', "#0000FF"], // Blue
    ['Open_circuit', "#FFC0CB"], // Pink
    ['Short', "#FF0000"], // Red
    ['Spur', "#FFA500"], // Orange
    ['Spurious_copper', "#FFFF00"] // Yellow
  ]);

  getColor(cls: string): string {
    return this.colorMap.get(cls) || "#FF0000"; // 默认颜色为红色
  }
}