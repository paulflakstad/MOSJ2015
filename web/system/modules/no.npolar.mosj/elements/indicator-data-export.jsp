<%-- 
    Document   : indicator-data-export
    Description: Exports data for a MOSJ parameter/chart as .csv or .xls format.
    Created on : May 27, 2015
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="org.apache.poi.ss.usermodel.Workbook" %>
<%@page import="org.apache.poi.ss.usermodel.Cell" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFCell" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFSheet" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFWorkbook" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFRow" %>
<%@page import="org.apache.poi.hssf.usermodel.*" %>
<%@page import="org.opencms.jsp.*" %>
<%@page import="org.opencms.file.*" %>
<%@page import="org.opencms.main.*" %>
<%@page import="org.opencms.xml.*" %>
<%@page import="org.opencms.json.*" %>
<%@page import="java.util.*" %>
<%@page import="java.io.OutputStream" %>
<%@page import="java.io.ByteArrayOutputStream" %>
<%@page import="java.io.BufferedReader" %>
<%@page import="java.io.StringReader" %>
<%@page import="java.nio.charset.Charset" %>
<%@page import="org.opencms.security.*" %>
<%@page import="no.npolar.util.*" %>
<%@page import="no.npolar.data.api.*" %>
<%@page import="no.npolar.data.api.mosj.*" %>
<%@page import="no.npolar.data.api.util.APIUtil" %>
<%@page trimDirectiveWhitespaces="true" pageEncoding="UTF-8" session="true" %>
<%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
//CmsObject cmso              = cms.getCmsObject();
//String requestFileUri       = cms.getRequestContext().getUri();
//String requestFolderUri     = cms.getRequestContext().getFolderUri();
//Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

final String FILE_TYPE_CSV = "csv";
final String FILE_TYPE_XLS = "xls";
final String DEFAULT_FILE_TYPE = FILE_TYPE_CSV;

String genType = request.getParameter("type");
if (genType == null || genType.trim().isEmpty()) {
    genType = DEFAULT_FILE_TYPE;
} else if (! (genType.equals(FILE_TYPE_CSV) || genType.equals(FILE_TYPE_XLS)) ) {
    out.println("Unsupported file type: " + genType);
    return;
}

Locale locale = new Locale("en");
try { locale = new Locale(request.getParameter("locale")); } catch (Exception e) {} // Switch to set locale, or retain default

MOSJService mosj = new MOSJService(locale, request.isSecure());
MOSJParameter mp = mosj.getMOSJParameter(request.getParameter("id"));

String fileName = mp.getTitle(locale).toLowerCase().replaceAll(" ", "-");

byte[] rawContent = null;
    
// Get the .csv file
String csvContent = mp.getAsCSV();

if (genType.equals(FILE_TYPE_CSV)) {
    csvContent = "\ufeff" + csvContent; // (not working) byte-order marker (BOM) to identify the CSV file as a Unicode file - Needed for Excel to know this file is UTF-8-encoded
    rawContent = csvContent.getBytes(Charset.forName("UTF-8"));

    //response.setContentType("application/csv;charset=UTF-8");
    //response.setContentType("application/csv;charset=Unicode");
    //response.setContentType("text/csv;charset=UTF-8");
    //response.setContentType("application/unknown"); //this also works

    //response.setContentType("application/x-msexcel;charset=UTF-8");
    cms.setContentType("text/csv;charset=UTF-8");
    response.setContentType("text/csv;charset=UTF-8");
    /*
    response.setContentLength(rawContent.length);

    //response.setHeader("Content-Disposition","attachment; filename=\"data.csv\""); // set the file name to whatever required..
    response.setHeader("Content-Disposition","attachment; filename=\"" + fileName + ".csv\"");

    //response.getOutputStream().write('\ufeff'); // (not working) byte-order marker (BOM) to identify the CSV file as a Unicode file - Needed for Excel to know this file is UTF-8-encoded

    OutputStream responseOutStream = response.getOutputStream();
    responseOutStream.write(rawContent, 0, rawContent.length);
    responseOutStream.flush();
    return;
    */
}

if (genType.equals(FILE_TYPE_XLS)) {
    HSSFWorkbook workbook = new HSSFWorkbook();
    
    HSSFSheet sheet = workbook.createSheet("Data");
    
    // populate the .xls file using the .csv file as base
    String currentLine = null;
    int rowNum = 0;
    BufferedReader br = new BufferedReader(new StringReader(csvContent));
    while ((currentLine = br.readLine()) != null) {
        rowNum++;
        HSSFRow row = sheet.createRow(rowNum);
        
        String csvParts[] = currentLine.split(";");
        for (int i = 0; i < csvParts.length; i++) {
            HSSFCell cell = row.createCell(i);
            String csvPart = csvParts[i];
            try {
                cell.setCellValue(csvPart);
            } catch (Exception ignore) {
                cell.setCellValue("");
            }
            
            if (rowNum > 1 && i > 1) {
                try {
                    if (locale.getLanguage().equalsIgnoreCase("no")) {
                        csvPart = csvPart.replaceAll("\\,", ".").replaceAll("\\.", ",");
                    }
                    cell.setCellValue(Double.valueOf(csvPart).doubleValue());
                    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
                } catch (Exception ignore) {}
            }
        }
    }

    ByteArrayOutputStream outByteStream = new ByteArrayOutputStream();
    workbook.write(outByteStream);
    rawContent = outByteStream.toByteArray();
    
    cms.setContentType("application/ms-excel;charset=UTF-8");
    response.setContentType("application/ms-excel;charset=UTF-8");
}

response.setContentLength(rawContent.length);

//response.setHeader("Content-Disposition","attachment; filename=\"data.csv\""); // set the file name to whatever required..
response.setHeader("Content-Disposition","attachment; filename=\"" + fileName + "." + genType + "\"");

//response.getOutputStream().write('\ufeff'); // (not working) byte-order marker (BOM) to identify the CSV file as a Unicode file - Needed for Excel to know this file is UTF-8-encoded

OutputStream responseOutStream = response.getOutputStream();
responseOutStream.write(rawContent);//, 0, rawContent.length);
responseOutStream.flush();
%>