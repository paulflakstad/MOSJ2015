<%-- 
    Document   : metadata.json
    Description: Exports indicator metadata in .json format. Used in the 
                    migration of some metadata, from OpenCms to the Data Centre.
    Created on : Jan 6, 2017, 8:40:40 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="java.text.SimpleDateFormat,
            org.opencms.xml.types.I_CmsXmlContentValue,
            org.opencms.xml.content.CmsXmlContent,
            org.opencms.xml.content.CmsXmlContentFactory,
            org.opencms.file.*,
            no.npolar.util.*,
            no.npolar.common.menu.*,
            java.util.*,
            org.opencms.flex.CmsFlexController,
            org.opencms.main.*,
            org.opencms.jsp.*,
            org.opencms.util.*,
            org.opencms.security.CmsRole" 
            contentType="text/html" 
            pageEncoding="UTF-8"
            session="true"
            trimDirectiveWhitespaces="true"
%><%!
// Default titles, used when the "Title" property is missing (shouldn't happen, this is just a precaution)
static final String NO_TITLE = "NO TITLE";

/**
 * Sorts the resources in the given list by their "Title" property.
 */
public List<CmsResource> sortByTitle(List<CmsResource> list, CmsObject cmso) throws CmsException {
    final CmsObject c = cmso;
    Collections.sort(list, new Comparator<CmsResource>() {
        public int compare(CmsResource o1, CmsResource o2) {
            try {
                return c.readPropertyObject(o1, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE).compareTo(
                            c.readPropertyObject(o2, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE)
                        );
            } catch (Exception e) {
                return 0;
            }
        }
    });
    return list;
}
%><%
// Muy importante!!! (One of "application/json" OR "application/javascript")
CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/json; charset=utf-8");

CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();

final String RES_TYPE       = "mosj_indicator";
final boolean LIST_SUBTREE  = true;

out.println("{");

String listFolderUri = request.getParameter("locale");

if (listFolderUri == null || listFolderUri.isEmpty()) {
    out.println("\"error\":\"Missing required parameter 'locale' in requested URL.\"");
    out.println("}");
    return;
}
Locale locale = null;
try {
    locale = new Locale(listFolderUri);
} catch (Exception e) {
    out.println("\"error\":\"Invalid value for parameter 'locale' in requested URL.\"");
    out.println("}");
    return;
}

if (!cmso.existsResource(listFolderUri)) {
    out.println("\"error\":\"There is no content in " + locale.getDisplayName(new Locale("en")) + " here.\"");
    out.println("}");
    return;
}

String loc = locale.getLanguage();

out.println("\"parameters\":[");

CmsResourceFilter filterIndictorFiles = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType(RES_TYPE).getTypeId());
List<CmsResource> indicatorFiles = cmso.readResources(listFolderUri, filterIndictorFiles, LIST_SUBTREE);
indicatorFiles = sortByTitle(indicatorFiles, cmso);
Iterator<CmsResource> iIndicatorFiles = null;

int numParameters = 0;

if (!indicatorFiles.isEmpty()) {
    iIndicatorFiles = indicatorFiles.iterator();
    
    while (iIndicatorFiles.hasNext()) {
        
        // Rough explanation:
        //
        // The [MonitoringData] is a wrapper that groups together [Parameter]s 
        // that share the same set of [Details] => Only indicators with multiple
        // set of details use multiple [MonitoringData] nodes.
        //
        // OUR GOAL HERE is to construct one json object per [Parameter], 
        // comprising all available metadata.
        // ---------------------------------------------------------------------
        // The anatomy of an indicator file:
        //
        // Typically, there is only 1 [MonitoringData] with 1 or 2 [Parameter]s.
        // However, there are exceptions, and we need to focus on the cases 
        // where we have multiple [MonitoringData] nodes, each one containing 
        // multiple [Parameter] nodes. See f.ex.:
        // http://www.mosj.no/en/fauna/marine/polar-bear.html
        //
        // Interesting paths:
        //
        //      If [2] is used, multiple nodes may exist
        //      If [1] is used, there's always just a single node
        //
        // MonitoringData[2]/Parameter[2]/ID[1]                             
        //      = Parameter's Data Centre ID
        // MonitoringData[2]/Details[1]/LastUpdate[1]                       
        //      = Last update
        // MonitoringData[2]/Details[1]/ExecutiveInstitutions[2]/Text[1]
        //      = Exec. inst. name
        // MonitoringData[2]/Details[1]/ExecutiveInstitutions[2]/URL[1]
        //      = Exec. inst. URL
        
        CmsResource indicatorFile = iIndicatorFiles.next();
        // Get all the data we need for the export
        String indTitle = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
        String indUri = cmso.getSitePath(indicatorFile);
        
        CmsXmlContent content = CmsXmlContentFactory.unmarshal(cmso, cmso.readFile(indicatorFile));
        
        // Albeit rare, multiple [MonitoringData] nodes may exist.
        List<I_CmsXmlContentValue> mdWrappers = content.getValuesByPath("MonitoringData", locale);
        for (I_CmsXmlContentValue mdWrapper : mdWrappers) {
            
            Date publishDate = null;
            SimpleDateFormat dfPublished = new SimpleDateFormat("yyyy-MM", locale);
            String lastUpdate = "null";
            try { 
                lastUpdate = content.getValue(mdWrapper.getPath().concat("/Details[1]/LastUpdate"), locale).getStringValue(cmso);
                publishDate = new Date(Long.valueOf(lastUpdate));
            } catch (Exception e) {}
            
            
            String execInstJson = "";
            List<I_CmsXmlContentValue> execInstWrappers = content.getValuesByPath(mdWrapper.getPath().concat("/Details[1]/ExecutiveInstitutions"), locale);
            for (I_CmsXmlContentValue execInstWrapper : execInstWrappers) {
                execInstJson += "{\"name\" : \"";
                try { 
                    String name = content.getValue(execInstWrapper.getPath().concat("/Text[1]"), locale).getStringValue(cmso);
                    execInstJson += CmsHtmlExtractor.extractText(name, "utf-8");
                    execInstJson += "\", \"name_html\" : \"" + CmsStringUtil.escapeHtml(name);
                    
                } catch (Exception e) {
                    execInstJson += "null";
                }
                execInstJson += "\", \"url\" : \"";
                try { 
                    String fullUrl = content.getValue(execInstWrapper.getPath().concat("/URL[1]"), locale).getStringValue(cmso);
                    execInstJson += fullUrl;
                    execInstJson += "\", \"@id\" : \"";
                    
                    try {
                        String domain = fullUrl.substring(fullUrl.indexOf("//")+2);
                        if (domain.contains("/")) {
                            domain = domain.substring(0, domain.indexOf("/"));
                        }
                        if (domain.startsWith("www.")) {
                            domain = domain.substring("www.".length());
                        }
                        execInstJson += domain;
                    } catch (Exception ee) {
                        execInstJson += "null";
                    }
                } catch (Exception e) {
                    execInstJson += "null";
                }
                execInstJson += "\" },";
            }
            if (!execInstJson.isEmpty()) {
                // remove the trailing comma
                execInstJson = execInstJson.substring(0, execInstJson.length() - 1);
            }
            
            // Each [MonitoringData] node can have N [Parameter] child nodes.
            // (We need only its ID, the rest if read from the [Details] node.)
            List<I_CmsXmlContentValue> paramWrappers = content.getValuesByPath(mdWrapper.getPath().concat("/Parameter"), locale);
            for (I_CmsXmlContentValue paramWrapper : paramWrappers) {
                
                String paramId = null;
                try {
                    paramId = content.getValue(paramWrapper.getPath().concat("/ID[1]"), locale).getStringValue(cmso);
                } catch (Exception e) {}
                
                out.print((numParameters++ > 0 ? "," : "") + "\n{\n");
                    out.println("\"id\" : \"http://api.npolar.no/indicator/parameter/" + paramId + "\",");
                    out.println("\"indicator_title\" : \"" + indTitle + "\",");
                    out.println("\"lang\" : \"" + loc + "\",");
                    out.println("\"uri\" : \"" + OpenCms.getLinkManager().getOnlineLink(cmso, indUri) + "\",");
                    out.println("\"authors\" : [" + execInstJson + "],");
                    out.println("\"published\" : \"" + (publishDate != null ? dfPublished.format(publishDate) : lastUpdate) + "\"");
                out.print("}");
            } // [Parameter] node loop, within this single [MonitoringData] node
            
        } // [MonitoringData] node loop, within this single indicator file
        
    } // indicator file loop
    
} // if (indicator files exist)

out.println("]");
out.println("}");
%>