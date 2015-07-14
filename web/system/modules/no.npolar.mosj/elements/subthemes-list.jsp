<%-- 
    Document   : subthemes-list
    Created on : Jul 1, 2015, 2:54:53 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.file.*,
                no.npolar.util.*,
                java.util.*,
                org.opencms.main.*,
                org.opencms.jsp.*,
                org.opencms.security.CmsRole"
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
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();

boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
boolean portal              = Boolean.valueOf(cms.property("portalpage", requestFileUri, "false")).booleanValue();
if (!portal) {
    try {
        if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId())
            portal = true;
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Portal page module not installed
    }
}

Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();

String listFolderUri        = requestFolderUri;
if (request.getParameter("folderUri") != null) {
    listFolderUri = request.getParameter("folderUri");
}

if (!cmso.existsResource(listFolderUri)) {
    out.println("<!-- ERROR: Requested listing of folder " + listFolderUri + ", but no such folder exists. -->");
    return;
}

%>
<section class="paragraph subthemes-list boxes clearfix">
<%

final String LABEL_INDICATORS = loc.equalsIgnoreCase("no") ? "Indikatorer" : "Indicators";
final String LABEL_INDICATORS_NONE = loc.equalsIgnoreCase("no") ? "Ingen indikatorer" : "No indicators";

CmsResourceFilter filterFileType = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId());
List<CmsResource> collectedFiles = cmso.readResources(listFolderUri, filterFileType, true);
collectedFiles = sortByTitle(collectedFiles, cmso);
Iterator<CmsResource> iCollectedFiles = null;
if (!portal) {
    if (collectedFiles.isEmpty()) {


        // Say so
        %>
        <em><%= LABEL_INDICATORS_NONE %></em>
        <%
    } else {
        iCollectedFiles = collectedFiles.iterator();
        %>
        <h3><%= LABEL_INDICATORS %></h3>
        <ul>
        <%
        while (iCollectedFiles.hasNext()) {
            CmsResource collectedFile = iCollectedFiles.next();
            String iTitle = cmso.readPropertyObject(collectedFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
            String iUri = cmso.getSitePath(collectedFile);
            %>
            <li><a href="<%= iUri %>"><%= iTitle %></a></li>
            <%
        }
        %>
        </ul>
        <%
    }
} else {
    if (collectedFiles.isEmpty()) {
    } else {
        out.println("<!-- collected " + collectedFiles.size() + " file(s) -->");
        iCollectedFiles = collectedFiles.iterator();
        while (iCollectedFiles.hasNext()) {
            CmsResource collectedFile = iCollectedFiles.next();
            String iTitle = cmso.readPropertyObject(collectedFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
            String iDescr = cmso.readPropertyObject(collectedFile, CmsPropertyDefinition.PROPERTY_DESCRIPTION, false).getValue(NO_DESCR);
            String iUri = cmso.getSitePath(collectedFile);
            out.println("<!-- processing " + iUri + " ... -->");
            if (!iUri.equals(requestFileUri)) {
                String iImage = cms.getRequestContext().removeSiteRoot(cmso.readPropertyObject(collectedFile, "image.thumb", false).getValue(""));
                if (iImage == null || iImage.equals("/")) {
                    iImage = "/" + loc + "/img/tema/placeholder-image.jpg";
                }
                %>
                <div class="layout-box featured-box hb-text">
                    <a href="<%= iUri %>" class="featured-link">
                        <div class="card">
                            <div class="autonomous">
                                <h2 class="portal-box-heading overlay"><span><%= iTitle %></span></h2>
                                <!--<div class="portal-box-text overlay"><%= iDescr %></div>-->
                                <%= ImageUtil.getImage(cms, iImage, iTitle, 1200, ImageUtil.SIZE_L, 70) %>
                                <!--<img width="500" height="234" alt="" src="/no/img/indikatorer/NP045713-isbjornunger-polar-bear-cubs-jon-aars.jpg?__scale=w:500,t:3,q:100">-->
                            </div>
                        </div><!-- .card -->
                    </a>
                </div>
                <%
            }
        }
    }
}
%>
</section>