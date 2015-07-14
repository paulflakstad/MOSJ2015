<%-- 
    Document   : new-menu.jsp (fetched from the 2014 version polarhistorie.no)
                 Adapted to the responsive website, and without dropdown menus.
    Created on : 14.sep.2010, 19:29:17
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.security.CmsRoleManager,
                 org.opencms.security.CmsRole,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.util.CmsHtmlExtractor,
                 java.io.IOException,
                 java.io.UnsupportedEncodingException,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Locale,
                 java.util.Iterator,
                 java.util.Date,
                 no.npolar.common.menu.*,
                 no.npolar.util.*" session="true" 
%><%!
public void printSubmenuForm(MenuItem current, CmsAgent cms, JspWriter out) throws IOException {
    if (current.getLevel() > 1)
        printSubmenuForm(current.getParent(), cms, out);
    List subItems = current.getSubItems();
    Iterator i = subItems.iterator();
    out.println("<form action=\"" + cms.link("navigate.jsp") + "\" method=\"get\">");
    out.println("<select name=\"navtarget\" onchange=\"submit()\">");
    while (i.hasNext()) {
        MenuItem mi = (MenuItem)i.next();
        out.println("<option value=\"" + mi.getUrl() + "\"" + (mi.isCurrent() || mi.isInPath() ? " selected=\"selected\"" : "") + ">" + mi.getNavigationText() + "</option>");
    }
    out.println("</select>");
    out.println("</form>");
}

public String getPropertyOrigin(String propertyName, String propertyValue, String resourceUri, CmsObject cmso) throws CmsException {
    while (true) {
        String pVal = cmso.readPropertyObject(resourceUri, propertyName, false).getValue(null);
        if (pVal != null && pVal.equals(propertyValue))
            return resourceUri; // Found the resource that had the property set, return it
        if (resourceUri.equals("/"))
            return null; // Property origin not found anywhere (we're at the root folder): return null
        resourceUri = CmsResource.getParentFolder(resourceUri); // Property origin not found on this file/folder, try the parent folder
    }
}

public List<MenuItem> getBreadCrumbItems(Menu menu, CmsAgent cms, String resourceUri) throws org.opencms.loader.CmsLoaderException, CmsException {
    // Fetch a list containing the current breadcrumb items
    List menuItems = menu.getCurrentPath();
    // Menu item object
    MenuItem mi = null;
    List breadCrumbs = new ArrayList();
    
    CmsObject cmso = cms.getCmsObject();    
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
    // The "home" URI - fetched from property, defaults to the locale folder if no property value is found
    final String HOME_URI = cms.link(cms.property("home-file", "search", "/".concat(loc).concat("/")));
    // Find the current request file URI, modify to remove "index.html" if needed
    if (resourceUri.endsWith("/index.html"))
        resourceUri = resourceUri.substring(0, resourceUri.lastIndexOf("index.html"));

    // Add the "home" menu item
    MenuItem homeMenuItem = new MenuItem(loc.equalsIgnoreCase("no") ? "Forsiden" : "Home", HOME_URI);
    if (!menuItems.isEmpty()) {
        if (!((MenuItem)(menuItems.get(0))).getUrl().equals(homeMenuItem.getUrl())) {
            menuItems.add(0, homeMenuItem);
        }
    } else {
        menuItems.add(0, homeMenuItem);
    }
    
    // Handle pages not referenced to in the menu
    if (menu.getElementByUrl(resourceUri) == null) {
        //final String EMPLOYEES_FOLDER = loc.equalsIgnoreCase("no") ? "/no/ansatte/" : "/en/people/";
        //final int TYPE_ID_PERSON = org.opencms.main.OpenCms.getResourceManager().getResourceType("person").getTypeId();
        //final int TYPE_ID_PERSONALPAGE = org.opencms.main.OpenCms.getResourceManager().getResourceType("personalpage").getTypeId();
        //final String EVENTS_FOLDER = loc.equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";
        //final int TYPE_ID_EVENT = org.opencms.main.OpenCms.getResourceManager().getResourceType("np_event").getTypeId();
        String requestFileUri = cms.getRequestContext().getUri();
        
        //try {
            // Handle case: Inject parent item for loose files whose parent/ancestor folder has a "Navigation Text" property value set.
            // (It true, then a breadcrumb parent item should be injected, pointing to that parent/ancestor folder's URI.)
            String requestFolderUri = cms.getRequestContext().getFolderUri();
            String parentText = cmso.readPropertyObject(requestFolderUri, "NavText", true).getValue(null);
            if (parentText != null) {
                // A "NavText" property value was found: Get the URI to the folder where the property value was set
                String parentUri = getPropertyOrigin("NavText", parentText, requestFolderUri, cmso);
                if (parentUri == null) {
                    throw new NullPointerException("Parent text '" + parentText + "' was found, but parent URI resolved to NULL.");
                }
                else if (!parentUri.equals(requestFileUri) && !requestFileUri.equals(parentUri.concat("index.html"))) {
                    // Inject the parent item, but only if the property value was NOT found on the current page itself (or an index page of the folder that contained the "NavText" property)
                    MenuItem parentMenuItem = new MenuItem(parentText, parentUri);
                    menuItems.add(parentMenuItem);
                }
            }
        //} catch (Exception e) {
            // ???
        //}
        
        // Handle the special case of "this is a page within an employee's section":
        // Each employee can have a "sub-site" - a set of pages inside their folder. But the menu contains only the employees folder.
        // So, to avoid breaking the breadcrumb, we must determine if we're viewing such a page, and if so, insert the employee's name
        // at the correct place, so we get f.ex.: Home -> Employees -> Paul-Inge Flakstad -> One of Paul's pages
        // (Not having this special handler would produce: Home -> Employees -> One of Paul's pages)
        /*if (requestFileUri.startsWith(EMPLOYEES_FOLDER)  // Require that we are inside the employees section
                && cmso.readResource(requestFileUri).getTypeId() != TYPE_ID_PERSON) { // AND require that the request file is NOT an employee's "main" page (that case is handled below)
            // The resource is within an employee's section
            //out.println("<!-- personalpage ID: " + TYPE_ID_PERSONALPAGE + " -->");
            //out.println("<!-- requested resource's ID: " + cmso.readResource(requestFileUri).getTypeId() + " -->");
            //out.println("<!-- requested resource's path: " + requestFileUri + " -->");
            boolean isMainPersonPage = cmso.readResource(requestFileUri).getTypeId() == TYPE_ID_PERSON;
            if (!isMainPersonPage) {
                
                //out.println("<!-- page is not of type person (" + TYPE_ID_PERSON + " / " + cmso.readResource(requestFileUri).getTypeId() + ") -->");
                // The resource is _not_ the "main" employee page,
                // assume that it is a page the employee has created himself/herself
                final String IMAGES_FOLDER = "/images/";
                String personFolderPath = cmso.readPropertyObject(requestFileUri, "gallery.startup", true).getValue(IMAGES_FOLDER).replace(IMAGES_FOLDER, "/");
                String personName = cms.property("Title", personFolderPath, "");
                MenuItem personMenuItem = new MenuItem(personName, personFolderPath);
                menuItems.add(personMenuItem);
                // Now add the page itself
                MenuItem personalPageItem = new MenuItem(cms.property("Title", requestFileUri, "NO TITLE"), requestFileUri);
                menuItems.add(personalPageItem);
            }
        }*/
        /*
        // Handle the special case of "this is a page within a specific event's folder":
        // Some events require more than one page - conferences and alike. Let's call them "big events". 
        // Big events have an event folder instead of a single event file. In this folder, all pages are placed.
        // We need to make sure the breadcrumb will reflect the event when viewing these pages.
        // For example: Home -> Events -> The big conference -> Programme
        // (Not having this special handler would produce: Home -> Events -> Programme)
        else if (requestFileUri.startsWith(EVENTS_FOLDER + "20") // Require that we are inside a sub-folder (a "year" folder) of the events folder
                && cmso.readResource(requestFileUri).getTypeId() != TYPE_ID_EVENT) { // AND require that the request file is NOT an event's "main" page (that case is handled below)
            // We're currently inside one of the "year" folders. We don't know yet if we're inside a big event's folder.
            // However, we can assume that if we find an index file in the current folder, it's a big event folder.
            // (The "year" folders should not directly contain index files themselves.)
            String bigEventIndexFilePath = cms.getRequestContext().getFolderUri().concat("index.html");
            if (cmso.existsResource(bigEventIndexFilePath) 
                    && cmso.readResource(bigEventIndexFilePath).getTypeId() == TYPE_ID_EVENT) {
                // There was an index file, and it was an event file. We can now safely assume that the current page is a big event page.
                // Now, to maintain breadcrumb integrity, insert the event's name
                String eventTitle = cmso.readPropertyObject(bigEventIndexFilePath, "Title", false).getValue("UNKNOWN EVENT");
                MenuItem eventMenuItem = new MenuItem(eventTitle, bigEventIndexFilePath.replace("/index.html", ""));
                menuItems.add(eventMenuItem);
                // Now add the page itself
                MenuItem eventSubpageItem = new MenuItem(cms.property("Title", requestFileUri, "NO TITLE"), requestFileUri);
                menuItems.add(eventSubpageItem);
            }
        }
        //*/
        // This is the standard routine for handling the case where the current page is not in the menu.
        // (And in that case, we need to add it at the end of the breadcrumb.)
        else {
            String unknownMenuItemTitle = "NO TITLE";
            
            // Title present as request attribute:
            if (cms.getRequest().getAttribute("title") != null) {
                String reqAttrTitle = (String)cms.getRequest().getAttribute("title");
                if (!reqAttrTitle.isEmpty()) {
                    unknownMenuItemTitle = reqAttrTitle;// + " (from req. attr.)";
                }
            }
            // No title present as request attribute:
            else {
                // Get the current page's title
                /*unknownMenuItemTitle = cms.property("Title", resourceUri, "NO TITLE");// + " (from title prop.)";
                if (cms.getCmsObject().readResource(resourceUri).isFolder() && unknownMenuItemTitle.equals("NO TITLE")) {
                    // The title above was fetched from a folder, and the folder had no title: try to fetch title from the index page of that folder
                    unknownMenuItemTitle = cms.property("Title", resourceUri.concat("index.html"), "NO TITLE");// + " (from title prop.)";
                }*/
                if (cms.getCmsObject().readResource(resourceUri).isFolder()) {
                    // The title above was fetched from a folder: try to fetch title from the index page of that folder
                    unknownMenuItemTitle = cms.property("Title", resourceUri.concat("index.html"), "NO TITLE");// + " (from title prop.)";
                } else {
                    unknownMenuItemTitle = cms.property("Title", resourceUri, "NO TITLE");// + " (from title prop.)";
                }
            }
            
            // Add the current page as a final item in the breadcrumb
            MenuItem unknownMenuItem = new MenuItem(unknownMenuItemTitle, resourceUri);
            menuItems.add(unknownMenuItem);
        }
    }
    
    return menuItems;
}

private static String m = "";
public String getSubTreeMenuItems(MenuItem mi) {
    //*
    try {
        if (mi.isParent()) {
            List subItems = mi.getSubItems();
            Iterator itr = subItems.iterator();

            m += "<ul" + (mi.getLevel() > 1 ? " class=\"snap-right\"" : " class=\"no-snap\"") + ">";
            while (itr.hasNext()) {
                MenuItem subItem = (MenuItem)itr.next();
                if (subItem.isParent()) {
                    m += "<li class=\"has_sub level"+subItem.getLevel() + (subItem.isInPath() ? " inpath" : "") + (subItem.isCurrent() ? " current" : "") + "\">" +
                                    "<a onmouseover=\"showSubMenu(this)\" href=\"" + subItem.getUrl() + "\">" +
                                        "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                    "</a>";
                    getSubTreeMenuItems(subItem);
                }
                else {
                    m += "<li class=\"level"+subItem.getLevel() + (subItem.isInPath() ? " inpath" : "") + (subItem.isCurrent() ? " current" : "") + "\">" +
                                    "<a href=\"" + subItem.getUrl() + "\">" +
                                        "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                    "</a>";
                } 
                m += "</li>";
            }
            m += "</ul>";
        }
        else {
            if (mi.getLevel() > 1) { // Do this _only_ for menu items below top level
                m += "<li class=\"" + "level"+mi.getLevel() + (mi.isInPath() ? " inpath" : "") + (mi.getParent().isInPath() ? " parentinpath" : "") + (mi.isCurrent() ? " current" : "") + "\">" +
                                "<a href=\"" + mi.getUrl() + "\">" +
                                    "<span class=\"navtext\">" + mi.getNavigationText() + "</span>" +
                                "</a>" +
                            "</li>";
            }
        }
    } 
    catch (Exception e) {
        m = e.getMessage();
    }
    return m;
    //*/
    //return "";
}

private static String menustring = "";
public String getMenuTreeAsHtml(MenuItem mi) {
    //*
    try {
        if (mi.isParent()) {
            List subItems = mi.getSubItems();
            Iterator itr = subItems.iterator();

            menustring += "<ul>";
            
            // make the first menu item the language switch
            
            
            while (itr.hasNext()) {
                MenuItem subItem = (MenuItem)itr.next();
                
                menustring += "<li class=\"" 
                                    + getMenuItemClass(subItem)
                                    //+ (subItem.isParent() ? "has_sub subitems " : "") 
                                    //+ "level"+subItem.getLevel() + (subItem.isInPath() ? " inpath" : "") 
                                    //+ (subItem.isCurrent() ? " current" : "") 
                                + "\">" 
                                    + getMenuItemLink(subItem);
                                    //+ "<a href=\"" + subItem.getUrl() + "\">"
                                    //    + "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>"
                                    //+ "</a>";
                if (subItem.isParent()) {
                    getMenuTreeAsHtml(subItem);
                }
                 
                menustring += "</li>";
            }
            menustring += "</ul>";
        }
        else {
            if (mi.getLevel() > 1) { // Do this _only_ for menu items below top level
                menustring += "<li class=\"" 
                                        + getMenuItemClass(mi)
                                        //+ "level"+mi.getLevel() 
                                        //+ (mi.isInPath() ? " inpath" : "") 
                                        //+ (mi.isCurrent() ? " current" : "") 
                                    + "\">"
                                + getMenuItemLink(mi)
                                //+ "<a href=\"" + mi.getUrl() + "\">"
                                //    + "<span class=\"navtext\">" + mi.getNavigationText() + "</span>"
                                //"+ </a>"
                            + "</li>";
            }
        }
    } 
    catch (Exception e) {
        menustring = e.getMessage();
    }
    return menustring;
}

public static String getMenuItemClass(MenuItem mi) {
    String s = "level"+mi.getLevel();
    if (mi.isParent())
        s += " has_sub subitems";
    if (mi.isInPath())
        s += " inpath";
    if (mi.isCurrent()) 
        s += " current";
    return s;
}
public static String getMenuItemLink(MenuItem mi) {
    return "<a href=\"" + mi.getUrl() + "\">" 
                + "<span class=\"navtext\">" 
                    + mi.getNavigationText().trim()
                + "</span>" 
            + "</a>";
}

public void printDropDown(JspWriter out, MenuItem mi) throws IOException {
    if (mi.isParent()) {
        List subItems = mi.getSubItems();
        Iterator itr = subItems.iterator();

        out.println("<ul" + (mi.getLevel() > 1 ? " class=\"snap-right\"" : " class=\"no-snap\"") + ">");
        while (itr.hasNext()) {
            MenuItem subItem = (MenuItem)itr.next();
            if (subItem.isParent()) {
                out.print("<li class=\"has_sub\">" +
                                "<a onmouseover=\"showSubMenu(this)\" href=\"" + subItem.getUrl() + "\">" +
                                    "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                "</a>");
                printDropDown(out, subItem);
            }
            else {
                out.print("<li>" +
                                "<a href=\"" + subItem.getUrl() + "\">" +
                                    "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                "</a>");
            } 
            out.println("</li>");
        }
        out.println("</ul>");
    }
    else {
        if (mi.getLevel() > 1) { // Do this _only_ for menu items below top level
            out.println("<li>" +
                            "<a href=\"" + mi.getUrl() + "\">" +
                                "<span class=\"navtext\">" + mi.getNavigationText() + "</span>" +
                            "</a>" +
                        "</li>");
        }
    }
}

public String normalizeBreadCrumb(String navigationText) throws java.io.UnsupportedEncodingException {
    // The maximum length of the last breadcrumb item
    final int BC_TEXT_MAXLENGHT = 32;
    // Remove any html tags present in the item
    String navText = navigationText;
    try {
        navText = CmsHtmlExtractor.extractText(navigationText, "utf-8");
    } catch (Exception e) {
        navText += "<!-- exception caught while normalizing: " + e.getMessage() + " -->";
    }
    // Replace any & characters
    navText = navText.replaceAll(" & ", " &amp; ");
    // This text can potentially be excessively long, so shorten it if neccessary
    if (navText.length() > BC_TEXT_MAXLENGHT) {
        navText = navText.substring(0, BC_TEXT_MAXLENGHT);
        // Don't break in the middle of a word
        navText = navText.substring(0, navText.lastIndexOf(" "));
        // Add dots to illustrate that the text is shortened
        navText += "&hellip;";
    }
    return navText;
}
%><%
// Create a JSP action element, and get the URI of the requesting file (the one that includes this menu)
CmsAgent                cms         = new CmsAgent(pageContext, request, response);
CmsObject               cmso        = cms.getCmsObject();
String                  resourceUri = cms.getRequestContext().getUri();
HttpSession             sess        = request.getSession();
CmsRoleManager          roleManager = OpenCms.getRoleManager();
boolean                 useNoSession= roleManager.hasRole(cms.getCmsObject(), CmsRole.VFS_MANAGER);
boolean                 localeChanged=false;
MenuFactory             mf          = null;
Menu                    menu        = null;
Locale                  locale      = cms.getRequestContext().getLocale();
String                  loc         = null;

// Set localization as session attribute (need to re-generate the menu if the locale changes)
if (sess.getAttribute("locale") == null) {
    sess.setAttribute("locale", locale);
}
else {
    if (sess.getAttribute("locale") != locale) {
        localeChanged = true;
        sess.setAttribute("locale", locale);
    }
}
// Done setting localization to session


loc = locale.toString();



// Existence check: menu file's name
String xml = request.getParameter("filename");

// If no parameter "filename" was set, try looking elsewhere for a filename/path
if (xml == null) {
    // If the requesting file is a menufile (then it has type ID 320), we set the menu path = the path to the requesting file
    if (cms.getCmsObject().readResource(resourceUri).getTypeId() == 320)
        xml = resourceUri;
    // If the file is of any other type, set the menu path to the value of the property XMLResourceUri (search parent folders for this property if not found)
    else {
        xml = cms.property("XMLResourceUri", "search");
        if (xml == null)
            xml = cms.property("menu-file", "search");
    }
}
// If the menu path has not been resolved at this point, throw an exception
if (xml == null)
    throw new NullPointerException("No path to menu file could be resolved.");
// Done with existence check




if (useNoSession == false) { // If useNoSession is true, the next section won't change anything
    // Determine if the menu has been updated since it was put in session, 
    // and if so, set the useNoSession variable:
    if (sess.getAttribute("menu") != null) { // Menu exists in session
        if (sess.getAttribute("menu_timestamp") == null) { // If a menu exists, but no timestamp, then regererate and set it
            useNoSession = true;
        } else { // Timestamp exists
            long menuStoreTime = ((Long)sess.getAttribute("menu_timestamp")).longValue();
            CmsResource menuResource = cms.getCmsObject().readResource(xml);
            /*//
            java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("dd. MMM yyyy HH:mm:ss", locale);
            out.println("\n");
            out.println("<!-- Menu placed in session : " + df.format(new Date(menuStoreTime)) + " -->");
            out.println("<!-- Menu last modified     : " + df.format(new Date(menuResource.getDateLastModified())) + " -->");
            out.println("<!-- NOW is                 : " + df.format(new Date()) + " -->");
            out.println("<!-- comparing menuResource.getDateLastModified() > menuStoreTime: " + menuResource.getDateLastModified() + " > " + menuStoreTime + " = " + (menuResource.getDateLastModified() > menuStoreTime) + " -->");
            //*/
            if (menuResource.getDateLastModified() > menuStoreTime) {
                useNoSession = true;
            }
        }
        //out.println("<!-- menu found in session, useNoSession=" + useNoSession + " -->");
    } else {
        //out.println("<!-- menu NOT found in session, useNoSession=" + useNoSession + " -->");
    }
    // Done determining if the menu has been updated since it was put in session
}




// If the menu is not in session, or if the locale has changed, 
// or if the menu needs to be re-generated due to updates or user type
if (sess.getAttribute("menu") == null || useNoSession || localeChanged) {
    try {
        // Create a menu factory. This class extends CmsJspXmlContentBean, so we pass the page context, request and response.
        mf = new MenuFactory(pageContext, request, response);
        // Instanciate the menu object by letting the menu factory process the xml file that holds the menu data.
        menu = mf.createFromXml(xml);
        // Set menu expand mode: don't hide menu items not "in path"
        menu.setExpandMode(true);
        // Save the menu as a session variable
        sess.setAttribute("menu", menu);
        // Save the menu creation timestamp as a session variable
        sess.setAttribute("menu_timestamp", new Date().getTime());
        //out.println("<!-- Created menu and placed it in session. -->");
    } catch (Exception e) { 
        out.println("Could not create the menu from resource '" + xml + "': " + e.getMessage()); 
    }
}
else {
    // Menu is already generated and stored in the session - get it
    menu = (Menu)sess.getAttribute("menu"); 
}
     
// Set the requesting resource as current menu item (more correctly: _try_ to do it - it may not exist in the menu at all)
try {
    menu.setCurrent(resourceUri);
} catch (Exception e) {
    //
}
     
if (cms.template("mainmenu")) {
    
    // Get the menu items at levelrange 1 to 2 as a list, and an iterator.
    List leftsideNavLinks = menu.getSubMenu(1, 2);
    if (leftsideNavLinks.size() == 0) {
        menu.setTraversalTypePreorder();
        leftsideNavLinks = menu.getSubMenu(1, 2);
    }
    //out.println("<h5>leftsideNavLinks.size(): " + leftsideNavLinks.size() + "</h5>");
    //out.println("<h5>menu.getDepth(): " + menu.getDepth() + "</h5>");
    Iterator i = leftsideNavLinks.iterator();
    if (i.hasNext()) {
        out.println("<div class=\"naviwrap\">");
        out.println("<ul class=\"menu\">");
        while (i.hasNext()) { 
            MenuItem mi = (MenuItem)i.next();
            String html = ("<li class=\"navitem_lvl" + mi.getLevel() + "\"");
            if (mi.isCurrent())
                html += (" id=\"current_lvl" + mi.getLevel() + "\">");
            else {
                html += ">";
            }
            html += ("<a class=\"navlink_lvl" + mi.getLevel() + "\" href=\"" + mi.getUrl() + "\">" +
                        "<span class=\"navtext_lvl" + mi.getLevel() + "\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span>" +
                     "</a>" +
                     "</li>");
            out.println(html);
        }
        out.println("</ul>");
        out.println("</div> <!-- END menu -->");
    }
} // if (cms.template("mainmenu"))


//
// Top menu (displays toplevel menu items)
//
if (cms.template("topmenu")) {
    List menuItems = menu.getSubMenu(1, 1);
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_topmenu\">");
        
        MenuItem mi = null;
        String html;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            html = "<li";
            if (mi.isInPath())
                html += " class=\"inpath\"";
            html += ">"; // Done with <li> tag
            html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span></a>";
            html += "</li>";
            out.println(html);
        }
        out.println("</ul>");
    }
} // if (cms.template("topmenu"))

//
// Top menu (displays toplevel menu items)
//
if (cms.template("topmenu-dd")) {
    out.print("<!-- Menu contains " + menu.getElements().size() + " items. Getting top level items ... ");
    List menuItems = menu.getSubMenu(1, 1);
    out.println("OK (" + menuItems.size() + " items). -->");
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_topmenu\">");
        
        MenuItem mi = null;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            out.print("<li");
            if (mi.isInPath())
                out.print(" class=\"inpath\"");
            out.print(">"); // Done with <li> tag
            out.print("<a href=\"" + mi.getUrl() + "\">" +
                          "<span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ").trim() + "</span>" +
                      "</a>");
            /*
            out.print("<a" + (mi.isParent() ? " onmouseover=\"showSubMenu(this)\"" : "") + " href=\"" + mi.getUrl() + "\">" +
                          "<span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span>" +
                      "</a>");
            
            // Now the dropdown part
            printDropDown(out, mi);
            */
            
            out.println("</li>");
            
        }
        out.println("</ul>");
    } else {
        //out.println("<!-- no menu items ... -->");
    }
} // if (cms.template("topmenu"))



//
// Small screen navigation
//
if (cms.template("submenu_small_screen")) {
    out.println("<!-- this is the small screen submenu script initiating -->");
    
    try {
        String html = "";
        boolean currentPrinted = false;
        //List breadcrumbItems = menu.getCurrentPath();
        List breadcrumbItems = getBreadCrumbItems(menu, cms, resourceUri);
        Iterator<MenuItem> i = breadcrumbItems.iterator();
        out.print("<!-- Using breadcrumb path: ");
        while (i.hasNext()) {
            MenuItem mi = i.next();
            out.print(mi.getNavigationText());
            out.print(i.hasNext() ? " :: " : "");
            List children = mi.getSubItems();
            if (children != null) {
                html += "<form action=\"" + cms.link("navigate.jsp") + "\" method=\"get\" style=\"padding-left:" + (mi.getLevel() - 1) + "em;\">";
                html += "<select name=\"navtarget\" onchange=\"submit()\">";

                html += "<option value=\"\">- " + (loc.equalsIgnoreCase("no") ? "Velg en side ..." : "Select a page ...") + "</option>";
                if (currentPrinted) {
                    //html += "<option value=\"\" selected=\"selected\">- " + (loc.equalsIgnoreCase("no") ? "Velg en side ..." : "Select a page ...") + "</option>";
                }

                Iterator<MenuItem> iChildren = children.iterator();
                while (iChildren.hasNext()) {
                    MenuItem child = iChildren.next();
                    html += "<option value=\"" + child.getUrl() + "\"" + (breadcrumbItems.contains(child) ? " selected=\"selected\"" : "") + ">" + child.getNavigationText() + "</option>";
                    if (child.isCurrent())
                        currentPrinted = true;
                }
                html += "</select>";
                html += "<input type=\"hidden\" name=\"ref\" value=\"" + cms.getRequestContext().getUri() + "\" />";
                html += "</form>";
            } 
        }
        out.println(" -->");

        if (!html.isEmpty()) {
            out.println("<nav id=\"nav_smallscreen_subs\">");

            out.println("<p id=\"subs-dd-label\">" + (loc.equalsIgnoreCase("no") ? "Sider" : "Pages") + " under <em>" 
                            //+ ((MenuItem)breadcrumbItems.get(0)).getNavigationText() 
                            + menu.getCurrentPath().get(0).getNavigationText()
                            + "</em></p>");
            out.println(html);
            
            //out.println("<p id=\"subs-dd-label\">Sider under " + menu.getCurrent().getNavigationText() + "</p>");
            //printSubmenuForm(menu.getCurrent(), cms, out);
            
            out.println("</nav>");
        }
        else {
            out.println("<!-- No navigation items to print, exiting ... -->");
        }
    } catch (Exception e) {
        out.println("<!-- Error: " + e.getMessage() + " -->");
    }
    
    out.println("<!-- this is the small screen submenu script exiting...\nMenu stats: " + menu.getElements().size() + " items, current is '" + menu.getCurrent().getUrl() + "' -->");
    return;
}

//
// Submenu (displays sublevel menu items)
//
if (cms.template("submenu")) {
    List currentPathMenuItems = menu.getCurrentPath();
    /*
    out.println("<!--\nSUBMENU CALLED\n-->");
    out.println("<!--\nFULL MENU:");
    Iterator<MenuItem> iAllItems = menu.getElements().iterator();
    while (iAllItems.hasNext()) {
        out.println("\n" + iAllItems.next().getNavigationText());
    }
    out.println("\n-->");
    out.println("<!-- Current is '" + menu.getCurrent().getNavigationText() + "' -->");
    */
    List menuItems = menu.getSubMenu(2);
    //menuItems = menu.getSubMenu(menu.getCurrentPath().get(0)); // Why dis no work?
    if (!menuItems.isEmpty()) {
        
        MenuItem mi = null;
        String html = "";
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            //out.print("<!-- Evaluating MenuItem '" + mi.getNavigationText() + "': ");
            if (mi.getParent().isInPath()) {
                //out.println(" in path -->");
                html += "<li class=\"navitem_lvl" + (mi.getLevel() - 1);
                //if (mi.isInPath() || mi.getParent().isInPath())
                if (currentPathMenuItems.contains(mi) || currentPathMenuItems.contains(mi.getParent()))
                    html += " inpath";
                if (mi.isCurrent())
                    html += "\" id=\"current_lvl" + (mi.getLevel() - 1);
                html += "\">"; // Done with <li> tag
                html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ").trim() + "</span></a>";
                html += "</li>";
            } 
            else {
                //out.println(" NOT in path -->");
            }
        }
        if (html.length() > 0) {
            out.println("<ul id=\"nav_submenu\">");
            out.println(html);
            out.println("</ul>");
        }
    }
} // if (cms.template("submenu"))


//
// Breadcrumb navigation
//
if (cms.template("breadcrumb")) {    
    // The breadcrumb label to use (like "You are here")
    final String BREADCRUMB_LABEL = "";
    // Get breadcrumb items - including injected ones
    List menuItems = getBreadCrumbItems(menu, cms, resourceUri);
    Iterator i = menuItems.iterator();
    
    // Start with the label, or just an empty string, if no label
    String html = CmsAgent.elementExists(BREADCRUMB_LABEL) ? ("<li>" + BREADCRUMB_LABEL + ": </li>") : "";
    
    // All regular breadcrumb items
    while (i.hasNext()) {
        MenuItem mi = (MenuItem)i.next();
        String navAttrTitle = CmsHtmlExtractor.extractText(mi.getNavigationText(), "utf-8").replaceAll(" & ", " &amp; ");
        String navText = normalizeBreadCrumb(mi.getNavigationText());
        //html += "\n<li>" + (i.hasNext() ? ("<a href=\"" + cms.link(mi.getUrl()) + "\" class=\"breadcrumb\">" + navText + "</a>") : navText) + "</li>"; // No link on last item
        html += "\n<li>" + (i.hasNext() ? ("<a href=\"" + cms.link(mi.getUrl()) + "\" class=\"breadcrumb\" title=\"" + navAttrTitle + "\">" + navText + "</a> <i class=\"icon-right-open-mini\"></i>") : navText) + "</li>"; // No link on last item
    }
    
    out.println("\n<ul id=\"nav_breadcrumb\">" + html + "\n</ul><!-- #nav_breadcrumb -->");
}




if (cms.template("submenu-nested")) {
    List<MenuItem> currentPath = menu.getCurrentPath();
    Iterator<MenuItem> i = currentPath.iterator();
    if (!currentPath.isEmpty()) {
        /*
        out.println("<!-- menu root is " + menu.getRoot().getUrl() + " (" + menu.getRoot().getNavigationText() + ") -->");
        out.print("<!-- current path is: ");
        while (i.hasNext()) {
            out.print(i.next().getUrl() + " :::: ");
        }
        out.println(" -->");
        */
        
        MenuItem currentTopLevel = currentPath.get(0);
        
        //out.println("<!-- current top level item is " + currentTopLevel.getUrl() + (currentTopLevel.equals(menu.getRoot()) ? " (ROOT)" : " (not ROOT)") + " -->");
        //MenuItem currentLowLevel = currentPath.get(currentPath.size()-1); // May be identical to currentTopLevel ...
        if (!currentTopLevel.equals(menu.getRoot())) {
            String leftMenu = getSubTreeMenuItems(currentTopLevel);
            //out.println("<ul id=\"nav_submenu\">");
            if (!leftMenu.isEmpty()) {
                out.println("<span id=\"navtitle\">" + currentTopLevel.getNavigationText() + "</span>");
                out.println(leftMenu);
            }
            //out.println("</ul>");
        }
    }
    // Reset static variable
    m = "";
}

//
// Small screen navigation
//
if (cms.template("submenu_small_screen_full")) {
    //out.println("<!-- this is the small screen submenu script initiating -->");
    //out.println("<!-- using " + cms.getRequestContext().getUri().replace("index.html", "") + " as current URL -->");
    
    int levelsPrinted = 0;
    
    try {
        String html = "";
        boolean currentFound = false;
        String levelUpUri = null;
        
        //List breadcrumbItems = menu.getCurrentPath();
        List breadcrumbItems = getBreadCrumbItems(menu, cms, resourceUri);
        
        if (!breadcrumbItems.isEmpty()) {
            out.println("<!-- There were " + breadcrumbItems.size() + " breadcrumb items for the current page -->");
        } else {
            out.println("<!-- There were no breadcrumb items, hiding the breadcrumb menu. -->");
        }
        
        List topMenuItems = menu.getSubMenu(1, 1);
        Iterator<MenuItem> iTop = topMenuItems.iterator();
        html += "<form action=\"" + cms.link("navigate.jsp") + "\" method=\"get\" style=\"padding-left:0;\">";
        html += "<select name=\"navtarget\" onchange=\"submit()\">";
        
        while (iTop.hasNext()) {
            MenuItem topItem = iTop.next();
            if (breadcrumbItems.contains(topItem))
                levelUpUri = topItem.getUrl();
            html += "<option value=\"" + topItem.getUrl() + "\"" + (breadcrumbItems.contains(topItem) ? " selected=\"selected\"" : "") + ">" + topItem.getNavigationText() + "</option>";
            if (topItem.isCurrent())
                currentFound = true;
        }
        html += "</select>";
        
        html += "</form>";
        
        
        Iterator<MenuItem> i = breadcrumbItems.iterator();
        out.print("<!-- Using breadcrumb path: ");
        while (i.hasNext()) {
            MenuItem mi = i.next();
            out.print(mi.getNavigationText());
            out.print(i.hasNext() ? " :: " : "");
            
            if (!i.hasNext() && !currentFound) {
                html += "<div style=\"padding-left:" + (levelsPrinted++ * 2.7) + "em;\">";
                if (levelUpUri != null) { // Should NEVER be null here
                    html += "<a class=\"navtarget\" href=\"" + levelUpUri + "\">"
                                + "<i class=\"icon-up-open-1\"></i>"
                                //+ "<span class=\"small-nav-up\"></span>"
                                //+ "<img src=\"http://astoneaves.com/wp-content/uploads/2013/05/Arrow1-Up.png\" alt=\"\" />"
                            + "</a>";
                }
                // last item in breadcrumb AND this is not an item that exists in the navigation
                html += "<span>" + mi.getNavigationText() + "</span></div>";
            }
            
            List children = mi.getSubItems();
            if (children != null) {
                boolean levelUpNeeded = !currentFound && levelUpUri != null;
                
                html += "<form action=\"" + cms.link("navigate.jsp") + "\" method=\"get\" style=\"padding-left:" + ((levelsPrinted++ * 2.7) + (levelUpNeeded ? 0 : 1)) + "em;\">";
                                
                if (levelUpNeeded) {
                    html += "<a class=\"navtarget\" href=\"" + levelUpUri + "\">"
                                + "<i class=\"icon-up-open-1\"></i>"
                                //+ "<span class=\"small-nav-up\"></span>"
                                //+ "<img src=\"http://astoneaves.com/wp-content/uploads/2013/05/Arrow1-Up.png\" alt=\"\" />"
                            + "</a>";
                }
                
                html += "<select name=\"navtarget\" onchange=\"submit()\">";

                if (!levelUpNeeded) {
                    html += "<option value=\"\">- " + (loc.equalsIgnoreCase("no") ? "Velg en side ..." : "Select a page ...") + "</option>";
                }
                
                // Reset here, before handling child items
                levelUpUri = null;

                Iterator<MenuItem> iChildren = children.iterator();
                while (iChildren.hasNext()) {
                    MenuItem child = iChildren.next();
                    if (breadcrumbItems.contains(child)) 
                        levelUpUri = child.getUrl();
                    html += "<option value=\"" + child.getUrl() + "\"" + (breadcrumbItems.contains(child) ? " selected=\"selected\"" : "") + ">" + child.getNavigationText() + "</option>";
                    if (cms.getRequestContext().getUri().replace("index.html", "").equals(child.getUrl())) {
                        currentFound = true;
                    }
                }
                html += "</select>";
                
                html += "<input type=\"hidden\" name=\"ref\" value=\"" + cms.getRequestContext().getUri() + "\" />";
                
                html += "</form>";
            } 
        }
        out.println(" -->");

        if (!html.isEmpty()) {
            out.println("<nav id=\"nav_smallscreen_subs\">");
            out.println(html);            
            out.println("</nav>");
        }
        else {
            out.println("<!-- No navigation items to print, exiting ... -->");
        }
    } catch (Exception e) {
        out.println("<!-- Error: " + e.getMessage() + " -->");
    }
    
    out.println("<!-- this is the small screen submenu script exiting...\nMenu stats: " + menu.getElements().size() + " items, current is '" + menu.getCurrent().getUrl() + "' -->");
    return;
}

if (cms.template("sitemap")) {
    String leftMenu = getSubTreeMenuItems(menu.getRoot());
    if (!leftMenu.isEmpty()) {
        out.println(leftMenu);
    }
    
    // Reset static variable
    m = "";
}

if (cms.template("full")) {
    // Reset static variable
    menustring = "";
    try {
        String fullMenu = getMenuTreeAsHtml(menu.getRoot());
        if (!fullMenu.isEmpty()) {
            
            out.println(fullMenu.replaceFirst("ul", "ul id=\"nav_topmenu\""));
            //String languageSwitchLink = 
            //fullMenu.replaceFirst("<li ", "<li class=\"level1\" id=\"\">".concat(languageSwitchLink).concat("</li><li "));
        }
    } catch (Exception e) {
        out.println("<!-- ERROR at menu.jsp[full]: " + e.getMessage() + " -->");
    }
}
%>