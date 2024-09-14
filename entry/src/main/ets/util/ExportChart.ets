@author bilibli

@Title: excel

@Package com.ht.ams.car.util

@Description: excel

@date 2020年5月29日 09点25分
  /
  public class ExcelUtil {
  /*

  @param - [lists 数据集, fieldMap （字段，中文）, response, fileName 文件名]

  @return com.ht.ussp.core.Result

  @Description: 导出excel

  @author 向舜捷

  @date 2020年5月29日 09点25分
  */
  public static Result downExcelForList(List<?> lists, LinkedHashMap<String, String> fieldMap, HttpServletResponse response, String fileName) {
  OutputStream os = null;
  try {
  setHeader(response, fileName);
  os = response.getOutputStream();
  listToExcel(lists, fieldMap, fileName).write(os);
  os.flush();
  os.close();
} catch (Exception e) {
  e.printStackTrace();
  return Result.fail(502, “导出失败”);
} finally {
  if (null != os) {
    try {
      os.flush();
      os.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

  }
  1
}
return Result.success();
}

private static void setHeader(HttpServletResponse response, String fileName) throws Exception {
  response.setContentType(“application/vnd.ms-excel”);
  String codedFileName = java.net.URLEncoder.encode(fileName , “UTF-8”);
  response.setCharacterEncoding(“utf-8”);
  response.setHeader(“content-disposition”, “attachment;filename=” + codedFileName+new SimpleDateFormat("yyyyMMddHHmmss ").format(new Date()) + “.xls”);
}

private static void setCellHead(HSSFSheet sheet, LinkedHashMap<String, String> fieldMap, HSSFCellStyle headStyle) {

  HSSFRow row1 = sheet.createRow(0);
  //设置行高
  row1.setHeight((short) 500);
  int i = 0;
  for (String colHead : fieldMap.values()) {
    HSSFCell cell = row1.createCell(i);
    cell.setCellValue(colHead);
    cell.setCellStyle(headStyle);
    i++;
  }
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
}

private static void setCell(HSSFWorkbook wb
, String fileName
, LinkedHashMap<String, String> fieldMap
, List<?> lists
, HSSFCellStyle headStyle
, HSSFCellStyle bodyStyle
) throws Exception {
  HSSFSheet sheet = null;
  int j = 0;
  if (lists == null || lists.size() == 0) {
    sheet = wb.createSheet(fileName);
    setCellHead(sheet, fieldMap, headStyle);
    for (int k = 0; k < fieldMap.keySet().size(); k++) {
      sheet.setColumnWidth(k, 20 * 256);
    }
  }else {
    for (int i = 0; i < lists.size(); i++) {
      if (i == 0) {
        sheet = wb.createSheet(fileName);
        setCellHead(sheet, fieldMap, headStyle);
      } else if (i % 30000 == 0) {
        j++;
        sheet = wb.createSheet(fileName + j);
        setCellHead(sheet, fieldMap, headStyle);
      }
      for (int k = 0; k < fieldMap.keySet().size(); k++) {
        sheet.setColumnWidth(k, 20 * 256);
      }
      Object item = lists.get(i);
      HSSFRow row = sheet.createRow(i + 1);
      //设置行高
      row.setHeight((short) 500);
      int x = 0;
      Class itemClazz = lists.get(0).getClass();
      for (String colBody : fieldMap.keySet()) {
        Field field = getFieldByName(colBody, itemClazz);
        field.setAccessible(true);
        HSSFCell c = row.createCell(x);
        if(field.get(item) instanceof Date){
          c.setCellValue(field.get(item)!=null?new SimpleDateFormat(“yyyy-MM-dd HH:mm”).format( field.get(item)):“”);
        }else if(field.get(item) == null){
          c.setCellValue(" ");
        }
        else{
          c.setCellValue(String.valueOf(field.get(item)));
        }
        c.setCellStyle(bodyStyle);
        x++;
      }
    }
  }
}

private static Field getFieldByName(String fieldName, Class<?> clazz) {
  Field[] selfFields = clazz.getDeclaredFields();
  for (Field field : selfFields) {
    if (field.getName().equals(fieldName)) {
      return field;
    }
  }

  Class<?> superClazz = clazz.getSuperclass();
  if (superClazz != null && superClazz != Object.class) {
    return getFieldByName(fieldName, superClazz);
  }

  //如果本类和父类都没有，则返回空
  return null;
  1
  2
  3
  4
  5
  6
  7
}

private static HSSFWorkbook listToExcel(List<?> lists,
  LinkedHashMap<String, String> fieldMap,
String fileName) throws Exception {
  // 创建HSSFWorkbook对象(excel的文档对象)
  HSSFWorkbook hssfWorkbook = new HSSFWorkbook();
  HSSFCellStyle headStyle = getHeadStyle(hssfWorkbook);
  HSSFCellStyle bodyStyle = getBodyStyle(hssfWorkbook);
  setCell(hssfWorkbook, fileName, fieldMap, lists, headStyle, bodyStyle);
  return hssfWorkbook;
}

private static HSSFCellStyle getHeadStyle(HSSFWorkbook hssfWorkbook) {
  HSSFCellStyle headStyle = hssfWorkbook.createCellStyle();
  headStyle.setFillForegroundColor(HSSFColor.PALE_BLUE.index);
  headStyle.setFillPattern(HSSFCellStyle.SOLID_FOREGROUND);
  headStyle.setBorderBottom(HSSFCellStyle.BORDER_THIN);
  headStyle.setBorderLeft(HSSFCellStyle.BORDER_THIN);
  headStyle.setBorderRight(HSSFCellStyle.BORDER_THIN);
  headStyle.setBorderTop(HSSFCellStyle.BORDER_THIN);
  headStyle.setAlignment(HSSFCellStyle.ALIGN_CENTER);
  // 纵向居中
  headStyle.setVerticalAlignment(CellStyle.VERTICAL_CENTER);

  HSSFFont font = hssfWorkbook.createFont();
  font.setFontName("黑体");
  //设置字体大小
  font.setFontHeightInPoints((short) 12);
