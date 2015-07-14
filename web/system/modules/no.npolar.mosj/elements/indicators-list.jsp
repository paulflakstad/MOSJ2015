<%-- 
    Document   : indicators-list
    Created on : Apr 21, 2015, 2:54:53 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.file.*,
                no.npolar.util.*,
                no.npolar.common.menu.*,
                java.util.*,
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

/**
 * ToDo: FIX THIS!!!
 */
public String getMenuItemPath(Menu m, String uri) {
    String s = "";
    //s += "<!-- checking menu path to " + uri + "... -->\n";
    MenuItem mi = m.getElementByUrl(uri);
    String miUri = uri;
    while (mi == null) {
        //s += "<!-- no menu path to miUri, checking parent folder ... -->\n";
        miUri = CmsResource.getParentFolder(miUri);
        mi = m.getElementByUrl(miUri);
        
        if (miUri.equals("/"))
            break;
    }
    
    //s += "<!-- url=" + miUri + ", mi=" + mi.getNavigationText() + " -->\n";
    
    if (mi != null) {
        List<MenuItem> parents = new ArrayList<MenuItem>();
        
        try {
            // Add the menu item as it is (it is the parent of the item at the given uri)
            if (!mi.getUrl().equals(uri)) {
                parents.add(mi);
                //s +="<!-- added parent " + mi.getNavigationText() + " -->\n";
            } else {
                //s += "<!-- current menu item matched given uri -->\n";
            }
            
            MenuItem parent = mi.getParent();
            //while (!parent.getUrl().matches("/)) {
            while (parent != null && !"/no/".equals(parent.getUrl().trim()) && !"/en/".equals(parent.getUrl().trim()) && !"ROOT".equals(parent.getUrl().trim())) {
                parents.add(parent);
                //s +="<!-- added parent " + parent.getNavigationText() + " (" + parent.getUrl() + ") -->\n";
                parent = parent.getParent();
            }
            Collections.reverse(parents);
            Iterator<MenuItem> iParents = parents.iterator();
            while (iParents.hasNext()) {
                s += iParents.next().getNavigationText().trim() + (iParents.hasNext() ? " <i class=\"icon-right-open-mini\"></i> " : "");
            }
        } catch (Exception e) {
            //s += "<!-- ERROR: " + e.getMessage() + " -->\n";
        }
    } else {
        s = null;//"<!-- No menu path here -->\n";
    }
    
    /*MenuItem current = m.getCurrent();
    try {
        //Menu m = new Menu(menu);
        m.setCurrent(uri);
        List<MenuItem> path = m.getCurrentPath();
        if (path.size() >= 1) {
            //path = path.subList(0, path.size()-1);
            Iterator<MenuItem> iPath = path.iterator();
            //s += "<aside class=\"page-path\">";
            while (iPath.hasNext()) {
                s += iPath.next().getNavigationText().trim() + (iPath.hasNext() ? " <i class=\"icon-right-open-mini\"></i> " : "");
            }
            //s += "</aside>";
        } else {
            s += "<!-- Path size was " + path.size() + " -->";
        }
    } catch (Exception e) {
        s += "<!-- Error constructing page path: " + e.getMessage() + " -->";
    }
    m.setCurrent(current);*/
    return s;
}
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
HttpSession sess            = request.getSession();

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

boolean listSubTree = false;
if (request.getParameter("subtree") != null) {
    listSubTree = Boolean.valueOf(request.getParameter("subtree"));
}

if (!cmso.existsResource(listFolderUri)) {
    out.println("<!-- ERROR: Requested listing of folder " + listFolderUri + ", but no such folder exists. -->");
    return;
}

%>
<section class="paragraph indicators-list boxes clearfix">
<%

final String LABEL_INDICATORS = loc.equalsIgnoreCase("no") ? "Indikatorer" : "Indicators";
final String LABEL_INDICATORS_NONE = loc.equalsIgnoreCase("no") ? "Ingen indikatorer" : "No indicators";

// Menu should already be generated and stored in the session - get it
Menu menu = (Menu)sess.getAttribute("menu"); 


CmsResourceFilter filterIndictorFiles = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId());
List<CmsResource> indicatorFiles = cmso.readResources(listFolderUri, filterIndictorFiles, listSubTree);
indicatorFiles = sortByTitle(indicatorFiles, cmso);
Iterator<CmsResource> iIndicatorFiles = null;
if (!portal) {
    if (indicatorFiles.isEmpty()) {


        // Say so
        %>
        <em><%= LABEL_INDICATORS_NONE %></em>
        <%
    } else {
        iIndicatorFiles = indicatorFiles.iterator();
        %>
        <h3><%= LABEL_INDICATORS %></h3>
        <ul class="blocklist">
        <%
        while (iIndicatorFiles.hasNext()) {
            CmsResource indicatorFile = iIndicatorFiles.next();
            String iTitle = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
            String iDescr = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_DESCRIPTION, false).getValue(NO_DESCR);
            String iUri = cmso.getSitePath(indicatorFile);
            String iMenuItemPath = getMenuItemPath(menu, iUri);
            %>
            <li style="border-bottom:1px solid #ddd; margin:0; padding:1em 0 0.5em 0;">
                <h3><a href="<%= iUri %>"><%= iTitle %></a></h3>
                <p class="page-descr">
                    <%= iMenuItemPath != null ? "<aside class=\"page-path tag\">".concat(iMenuItemPath).concat("</aside> ") : "" %>
                    <%= CmsStringUtil.trimToSize(CmsHtmlExtractor.extractText(iDescr, "UTF-8"), 180, "&hellip;") %>
                </p>
            </li>
            <%
        }
        %>
        </ul>
        <%
    }
} else {
    if (indicatorFiles.isEmpty()) {
    } else {
        iIndicatorFiles = indicatorFiles.iterator();
        while (iIndicatorFiles.hasNext()) {
            CmsResource indicatorFile = iIndicatorFiles.next();
            String iTitle = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
            String iDescr = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_DESCRIPTION, false).getValue(NO_DESCR);
            String iUri = cmso.getSitePath(indicatorFile);
            String iImage = cms.getRequestContext().removeSiteRoot(cmso.readPropertyObject(indicatorFile, "image.thumb", false).getValue(""));
            if (iImage == null || iImage.equals("/")) {
                iImage = "/" + loc + "/img/tema/placeholder-image.jpg";
            }
            %>
            <div class="layout-box featured-box hb-text">
                <a href="<%= iUri %>" class="featured-link">
                    <div class="card">
                        <div class="autonomous">
                            <h2 class="portal-box-heading overlay"><span><%= iTitle %></span></h2>
                            <div class="portal-box-text overlay"><p><%= CmsHtmlExtractor.extractText(iDescr, "UTF-8") %></p></div>
                            <%= ImageUtil.getImage(cms, iImage, iTitle, 1200, ImageUtil.SIZE_L, 80) %>
                            <!--<%= ImageUtil.getImage(cms, iImage) %>-->
                            <!--<img width="500" height="234" alt="" src="/no/img/indikatorer/NP045713-isbjornunger-polar-bear-cubs-jon-aars.jpg?__scale=w:500,t:3,q:100">-->
                        </div>
                    </div><!-- .card -->
                </a>
            </div>
            <%
        }
    }
}
%>
</section>