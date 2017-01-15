<%-- 
    Document   : indicator-data-export
    Description: Exports data for a MOSJ parameter/chart as .csv or .xls format.
    Created on : May 27, 2015
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%>
<%@page import="org.opencms.xml.types.I_CmsXmlContentValue"%>
<%@page import="org.apache.poi.ss.usermodel.Workbook" %>
<%@page import="org.apache.poi.ss.usermodel.Cell" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFCell" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFSheet" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFWorkbook" %>
<%@page import="org.apache.poi.xssf.usermodel.XSSFRow" %>
<%@page import="org.apache.poi.xssf.usermodel.*" %>
<%@page import="org.opencms.jsp.*" %>
<%@page import="org.opencms.file.*" %>
<%@page import="org.opencms.main.*" %>
<%@page import="org.opencms.xml.*" %>
<%@page import="org.opencms.xml.content.*" %>
<%@page import="org.opencms.json.*" %>
<%@page import="org.opencms.util.CmsUUID" %>
<%@page import="java.util.*" %>
<%@page import="java.io.OutputStream" %>
<%@page import="java.io.ByteArrayOutputStream" %>
<%@page import="java.io.BufferedReader" %>
<%@page import="java.io.StringReader" %>
<%@page import="java.net.URLDecoder"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="java.nio.charset.Charset" %>
<%@page import="org.opencms.security.*" %>
<%@page import="no.npolar.util.*" %>
<%@page import="no.npolar.data.api.*" %>
<%@page import="no.npolar.data.api.mosj.*" %>
<%@page import="no.npolar.data.api.util.APIUtil" %>
<%@page trimDirectiveWhitespaces="true" pageEncoding="UTF-8" session="true" %>
<%!
public List<String> getTimeSeries(CmsObject cmso, CmsXmlContent xml, Locale locale, String title) {
    List<String> tsIds = new ArrayList<String>(2);
    try {
        // Get a list of all the Parameter content nodes present on this page,
        // for example:
        // "MonitoringData[1]/Parameter[1]"
        // "MonitoringData[1]/Parameter[2]"
        // "MonitoringData[2]/Parameter[1]"
        List<I_CmsXmlContentValue> pNodes = xml.getValuesByPath("MonitoringData/Parameter", locale);

        for (I_CmsXmlContentValue pNode : pNodes) {
            try {

                String pTitle = xml.getValue(pNode.getPath().concat("/Title"), locale).getStringValue(cmso);
                // Compare the given title to this parameter's title
                if (pTitle.equals(title)) {
                    // The title matched => This is the one we want = Get the
                    // IDs for all time series that are part of this parameter

                    // To get the IDs, we must look at all the children of this
                    // "MonitoringData/Parameter" node
                    List<I_CmsXmlContentValue> pSubVals = xml.getSubValues(pNode.getPath(), locale);
                    for (I_CmsXmlContentValue pSubVal : pSubVals) {
                        
                        if (pSubVal.getName().equals("TimeSeries")) {
                            // This is a time series - extract its ID and add it
                            // to our list
                            for (I_CmsXmlContentValue tsVal : xml.getSubValues(pSubVal.getPath(), locale)) {
                                if (tsVal.getName().equals("TimeSeriesID")) {
                                    tsIds.add(tsVal.getStringValue(cmso));
                                }
                            }
                        }
                    }
                    break;
                }
            } catch (Exception ee) {
            }
        }
    } catch (Exception e) {
        // No parameter nodes present
    }
    return tsIds;
}
%>
<%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
//String requestFileUri       = cms.getRequestContext().getUri();
//String requestFolderUri     = cms.getRequestContext().getFolderUri();
//Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

final String FILE_TYPE_CSV = "csv";
final String FILE_TYPE_XLS = "xlsx";
final String DEFAULT_FILE_TYPE = FILE_TYPE_CSV;

// ToDo: Rename "genType" => "fileFormat"
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
TimeSeriesCollection tsc = null;

String pid = request.getParameter("id"); // = MOSJ parameter ID (old version)
String indicator = request.getParameter("indicator");
String name = request.getParameter("name");

if (pid == null && indicator == null && name == null) {
    out.println("Not enough details were provided. Please try again.");
    return;
}

if (pid != null) {
    // Old routine
    tsc = mosj.getMOSJParameter(pid).getTimeSeriesCollection();
} else if (indicator != null) {
    // New routine
    name = URLDecoder.decode(name, "UTF-8");
    // get the correct parameter (chart / time series coll.)
    CmsXmlContent xml = CmsXmlContentFactory.unmarshal(cmso, cmso.readResource(CmsUUID.valueOf(indicator)), request);
    List<String> tsIds = getTimeSeries(cmso, xml, locale, name);
    if (tsIds.size() > 0) {
        tsc = mosj.createTimeSeriesCollection(tsIds, name);
    }
}

// If our TimeSeriesCollection instance is still null, something's very wrong
if (tsc == null) {
    out.println("A critical error occurred during file export. Please try again.");
    return;
}

String fileName = APIUtil.toURLFriendlyForm(tsc.getTitle()).replaceAll("\\.", "-");

byte[] rawContent = null;
    
// Get the .csv file
String csvContent = tsc.getAsCSV();

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
    XSSFWorkbook workbook = new XSSFWorkbook();
    
    XSSFSheet sheet = workbook.createSheet("Data");
    
    // populate the .xls file using the .csv file as base
    String currentLine = null;
    int rowNum = 0;
    BufferedReader br = new BufferedReader(new StringReader(csvContent));
    while ((currentLine = br.readLine()) != null) {
        rowNum++;
        
        if (rowNum == 1) {
            XSSFRow titleRow = sheet.createRow(rowNum);
            titleRow.createCell(0).setCellValue(tsc.getTitle());
            rowNum++;
        }
        
        XSSFRow row = sheet.createRow(rowNum);
        
        String csvParts[] = currentLine.split(";");
        for (int i = 0; i < csvParts.length; i++) {
            XSSFCell cell = row.createCell(i);
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