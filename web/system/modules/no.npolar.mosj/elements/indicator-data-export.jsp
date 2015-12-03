<%-- 
    Document   : indicator-data-export
    Description: Exports data for a MOSJ parameter identified by an "id" parameter to a CSV file.
                    The locale is set via a "locale" parameter (defaults to English).
    Created on : May 27, 2015
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.jsp.*,
            org.opencms.file.*,
            org.opencms.main.*,
            org.opencms.xml.*,
            org.opencms.json.*,
            java.util.*,
            java.nio.charset.Charset,
            org.opencms.security.*,
            no.npolar.util.*,
            no.npolar.data.api.*,
            no.npolar.data.api.mosj.*,
            no.npolar.data.api.util.APIUtil" pageEncoding="utf-8" session="true"
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
//CmsObject cmso              = cms.getCmsObject();
//String requestFileUri       = cms.getRequestContext().getUri();
//String requestFolderUri     = cms.getRequestContext().getFolderUri();
//Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

Locale locale = new Locale("en");
try { locale = new Locale(request.getParameter("locale")); } catch (Exception e) {} // Switch to set locale, or retain default

MOSJService mosj = new MOSJService(locale, request.isSecure());
MOSJParameter mp = mosj.getMOSJParameter(request.getParameter("id"));

String csvContent = mp.getAsCSV();
csvContent = "\ufeff" + csvContent; // (not working) byte-order marker (BOM) to identify the CSV file as a Unicode file - Needed for Excel to know this file is UTF-8-encoded
byte[] rawContent = csvContent.getBytes(Charset.forName("UTF-8"));

//response.setContentType("application/csv;charset=UTF-8");
//response.setContentType("application/csv;charset=Unicode");
//response.setContentType("text/csv;charset=UTF-8");
//response.setContentType("application/unknown"); //this also works

//response.setContentType("application/x-msexcel;charset=UTF-8");
cms.setContentType("text/csv;charset=UTF-8");
response.setContentType("text/csv;charset=UTF-8");

response.setContentLength(rawContent.length);

//response.setHeader("Content-Disposition","attachment; filename=\"data.csv\""); // set the file name to whatever required..
response.setHeader("Content-Disposition","attachment; filename=\"" + mp.getTitle(locale).toLowerCase().replaceAll(" ", "-") + ".csv\"");

//response.getOutputStream().write('\ufeff'); // (not working) byte-order marker (BOM) to identify the CSV file as a Unicode file - Needed for Excel to know this file is UTF-8-encoded

response.getOutputStream().write(rawContent, 0, rawContent.length);
response.getOutputStream().flush();
%>