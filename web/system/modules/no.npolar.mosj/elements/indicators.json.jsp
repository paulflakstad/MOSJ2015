<%-- 
    Document   : indicators-list
    Created on : Apr 21, 2015, 2:54:53 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.file.*,
                no.npolar.util.*,
                no.npolar.common.menu.*,
                java.util.*,
                org.opencms.flex.CmsFlexController,
                org.opencms.main.*,
                org.opencms.jsp.*,
                org.opencms.util.*,
                org.opencms.security.CmsRole"
                session="true"
%><%!
static final String NO_TITLE = "NO TITLE";
static final String NO_DESCR = "NO DESCR";

public List<CmsResource> sortByTitle(List<CmsResource> list, CmsObject cmso) throws CmsException {
    final CmsObject c = cmso;
    Collections.sort(list, new Comparator<CmsResource>() {
        public int compare(CmsResource o1, CmsResource o2) {
            try {
                return c.readPropertyObject(o1, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE).compareTo(c.readPropertyObject(o2, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE));
            } catch (Exception e) {
                return 0;
            }
        }
    });
    return list;
}
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();

// Muy importante!!! (One of "application/json" OR "application/javascript")
CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/json; charset=utf-8");

out.println("{");

String listFolderUri = request.getParameter("locale");

if (listFolderUri == null || listFolderUri.isEmpty()) {
    out.println("\"error\":\"Missing required parameter 'locale'.\"");
    out.println("}");
    return;
}
Locale locale = null;
try {
    locale = new Locale(listFolderUri);
} catch (Exception e) {
    out.println("\"error\":\"Invalid value for parameter 'locale'.\"");
    out.println("}");
    return;
}

if (!cmso.existsResource(listFolderUri)) {
    out.println("\"error\":\"There is no content in " + locale.getDisplayName(new Locale("en")) + ".\"");
    out.println("}");
    return;
}

out.println("\"indicators\":[");

final boolean LIST_SUBTREE = true;
CmsResourceFilter filterIndictorFiles = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId());
List<CmsResource> indicatorFiles = cmso.readResources(listFolderUri, filterIndictorFiles, LIST_SUBTREE);
indicatorFiles = sortByTitle(indicatorFiles, cmso);
Iterator<CmsResource> iIndicatorFiles = null;

if (!indicatorFiles.isEmpty()) {
    iIndicatorFiles = indicatorFiles.iterator();
    
    while (iIndicatorFiles.hasNext()) {
        CmsResource indicatorFile = iIndicatorFiles.next();
        String iTitle = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
        String iUri = cmso.getSitePath(indicatorFile);
        out.println("{");
        out.println("\"title\":\"" + iTitle + "\", ");
        out.println("\"id\":\"" + cmso.readResource(iUri).getResourceId() + "\", ");
        out.println("\"url\":\"" + OpenCms.getLinkManager().getOnlineLink(cmso, iUri) + "\"");
        out.println("}".concat(iIndicatorFiles.hasNext() ? ", " : ""));
    }
    
}

out.println("]");
out.println("}");
%>