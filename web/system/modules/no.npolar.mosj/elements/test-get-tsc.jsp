<%-- 
    Document   : test-get-tsc
    Description: Tests getting a TimeSeriesCollection via an indicator file's
                    OpenCms UUID and the title of the parameter.
                    Related to the file export feature.
    Created on : Jan 14, 2017, 12:10:22 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="java.net.URLDecoder"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="org.opencms.xml.types.I_CmsXmlContentValue"%>
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
<%@page import="org.opencms.xml.content.*" %>
<%@page import="org.opencms.json.*" %>
<%@page import="org.opencms.util.CmsUUID" %>
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

String pid = request.getParameter("id"); // = MOSJ parameter ID (old version)
String indicator = request.getParameter("indicator"); // UUID for indicator page
String name = request.getParameter("name"); // "URL-friendly" name of parameter/chart


// Test values
// Indicator file's UUID
indicator = "7baecc92-9d82-11e4-833c-d067e5371a66";//cmso.readIdForUrlName("/no/fauna/marin/lomvi.html").getStringValue();
// Parameter's title (simplified)
name = URLDecoder.decode(URLEncoder.encode("Kvikksølv (Hg) i egg fra polarlomvi, våtvekt", "UTF-8"), "UTF-8");
locale = new Locale("no");





MOSJService mosj = new MOSJService(locale, request.isSecure());
TimeSeriesCollection tsc = null;

if (pid == null && indicator == null && name == null) {
    // Handle missing details
}

if (pid != null) {
    MOSJParameter mp = mosj.getMOSJParameter(pid);
    tsc = mp.getTimeSeriesCollection();
} else if (indicator != null) {
    
    CmsResource indicatorResource = cmso.readResource(CmsUUID.valueOf(indicator));
    out.println("<p>Using indicator " + indicatorResource.getRootPath() + "</p>");
    
    // get the correct parameter (chart / time series coll.)
    CmsXmlContent xml = CmsXmlContentFactory.unmarshal(cmso, indicatorResource, request);
    List<String> tsIds = getTimeSeries(cmso, xml, locale, name);
    if (tsIds.size() > 0) {
        tsc = mosj.createTimeSeriesCollection(tsIds, name);
    }
    /*
    try {
        // Get a list of all the Parameter content nodes present on this page
        // We'll get e.g. 
        // "MonitoringData[1]/Parameter[1]", 
        // "MonitoringData[1]/Parameter[2]" and
        // "MonitoringData[2]/Parameter[1]"
        List<I_CmsXmlContentValue> pNodes = xml.getValuesByPath("MonitoringData/Parameter", locale);
        
        for (I_CmsXmlContentValue pNode : pNodes) {
            try {
                
                String pTitle = xml.getValue(pNode.getPath().concat("/Title"), locale).getStringValue(cmso);
                out.println("Parameter: " + pTitle + "<br>");
                
                List<I_CmsXmlContentValue> pSubVals = xml.getSubValues(pNode.getPath(), locale);
                for (I_CmsXmlContentValue pSubVal : pSubVals) {
                    if (pSubVal.getName().equals("TimeSeries")) {
                        for (I_CmsXmlContentValue tsVal : xml.getSubValues(pSubVal.getPath(), locale)) {
                            if (tsVal.getName().equals("TimeSeriesID")) {
                                out.println("  Time series: " + tsVal.getStringValue(cmso) + "<br>");
                            }
                        }
                    }
                }
            } catch (Exception ee) {
            }
        }
         
    } catch (Exception e) {
        // No parameter nodes present
    }
    //*/
    
    /*
    for (String path : xml.getNames(locale)) {
        if (path.contains("/Parameter[")) {
            List<I_CmsXmlContentValue> vals = xml.getValuesByPath(path, locale);
            for (I_CmsXmlContentValue val : vals) {
                List<I_CmsXmlContentValue> subvals = xml.getSubValues(val.getPath(), locale);
                if (!subvals.isEmpty()) {
                    out.println("<p>Parameter <tt>" + val.getPath() + "</tt> has sub-values:</p>");
                    out.println("<ul>");
                    for (I_CmsXmlContentValue subval : subvals) {
                        out.print("<li>");
                        out.print(subval);
                        out.println("</li>");
                    }
                    out.println("</ul>");
                }
            }
        }
    }
    //*/
    //tsc = mosj.c
}

out.println("<p>Created time series collection:</p>"
        + "<h1>" + tsc.getTitle() + " (" + tsc.getTimeSeries().size() + " time series)</h1>");
for (TimeSeries ts : tsc.getTimeSeries()) {
    out.println("<h2> - " + ts.getTitle() + "</h2>");
}

out.println(tsc.getAsTable("table", "responsive"));
%>