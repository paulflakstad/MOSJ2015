<%-- 
    Document   : ivorypage.jsp
    Created on : 02.jun.2010, 15:18:49
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.*,
                 no.npolar.util.contentnotation.*,
                 java.util.Locale,
                 java.util.Date,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsUser,
                 org.opencms.file.CmsResource,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.relations.CmsCategory,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}
%><%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

HttpSession sess                    = cms.getRequest().getSession(true);

// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";

// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Labels
final String LABEL_BY               = cms.labelUnicode("label.pageelements.by");
final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.pageelements.lastmodified");
final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.pageelements.dateformat.normal");
// File information variables
String byline                       = null;
String author                       = null;
String authorMail                   = null;
//String shareLinksString             = null;
//boolean shareLinks                  = false;
// XML content containers
I_CmsXmlContentContainer container  = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
String imgUri                       = null;
// Include-file variables
String includeFile                  = cms.property("template-include-file");
boolean wrapInclude                 = cms.property("template-include-file-wrap") != null ?
                                            (cms.property("template-include-file-wrap").equalsIgnoreCase("outside") ? false : true) : true;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = new String[] { "head", "foot" };
try { elements = cms.getTemplateIncludeElements(); } catch (Exception e) { elements = new String[] { "head", "foot" }; } // Should move this to CmsAgent


/*
final boolean SPECIES_PAGE          = requestFolderUri.startsWith(loc.equalsIgnoreCase("no") ? "/no/arter/" : "/en/species/"); // The parent folder containing all species pages
final String TITLE_RED_LIST_STATUS  = loc.equalsIgnoreCase("no") ? "Rødlistestatus" : "Red List status"; // The title for the "Red List status" category
final String RED_LIST_STATUS_PATH   = "redlist/"; // The (relative) path to the "Red List status" category
String redListStatus                = null;
*/

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);

//
// Get file creation and last modification info
//
CmsResource reqFile = cmso.readResource(requestFileUri);
CmsUser creatorUser = cmso.readUser(reqFile.getUserCreated()); // Get the user who created the file
CmsUser modUser = cmso.readUser(reqFile.getUserLastModified()); // Get the user who modified the file
String creatorName  = creatorUser.getFirstname() + " " + creatorUser.getLastname();
String modifierName = modUser.getFirstname() + " " + modUser.getLastname();
Date modifiedDate = new Date(reqFile.getDateLastModified()); // Create dates (representing the moment in time they are created. These objects are changed below.)
Date createdDate = new Date(reqFile.getDateCreated());
SimpleDateFormat dFormat = new SimpleDateFormat(PAGE_DATE_FORMAT, locale); // Create the desired output format
//out.println("Created by " + creatorName + " at " + dFormat.format(createdDate) + ".");
//out.println("Last modified by " + modifierName + " at " + dFormat.format(modifiedDate) + ".");


// IMPORTANT: Do this *after* calling the outer template!
ContentNotationResolver cnr = null;
try {
    cnr = (ContentNotationResolver)session.getAttribute(ContentNotationResolver.SESS_ATTR_NAME);
    //out.println("\n\n<!-- Content notation resolver resolver ready - " + cnr.getGlobalFilePaths().size() + " global files loaded. -->");
} catch (Exception e) {
    out.println("\n\n<!-- Content notation resolver needs to be initialized before it can be used. -->");
}


// Load the file
container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
// Set the content "direct editable" (or not)
cms.editable(EDITABLE);

//
// Process file contents
//
while (container.hasMoreContent()) {
    //out.println("<div class=\"page\">"); // REMOVED <div class="page">
    
    //out.println("<article class=\"main-content\">");
    
    pageTitle = cms.contentshow(container, "PageTitle");
    pageIntro = cms.contentshow(container, "Intro");
    author = cms.contentshow(container, "Author");
    authorMail = cms.contentshow(container, "AuthorMail");
    imgUri = cms.contentshow(container, "HeroImage");
    /*shareLinksString= cms.contentshow(container, "ShareLinks");
    if (!CmsAgent.elementExists(shareLinksString))
        shareLinksString = "false"; // Default value if this element does not exist in the file (backward compatibility)

    try {
        shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
    } catch (Exception e) {
        shareLinks = false; // Default value if above line fails (it shouldn't, but just to be safe...)
    }*/
    
    // Author and/or translator names - print them as mailto-links if e-mail addresses are present
    //if (CmsAgent.elementExists(author) || shareLinks) {
    if (CmsAgent.elementExists(author)) {
        byline = "<div class=\"byline\">";
        if (CmsAgent.elementExists(author)) {
            byline += "<div class=\"names\">";
            author = CmsAgent.removeUsername(author); // I.e. convert "Paul Flakstad (paul)" to "Paul Flakstad"
            byline += LABEL_BY + " ";
            byline += (CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author);
            //byline += "&nbsp;&ndash;&nbsp;"; // Dash between name(s) and timestamp
            byline += "</div><!-- .names -->";
        }
        /*if (shareLinks) {
            byline += cms.getContent(SHARE_LINK_MIN);
        }*/
        byline += "</div><!-- .byline -->";
    }

    if (CmsAgent.elementExists(authorMail)) {
        byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    /*
    //
    // For species pages, check categories for Red List status (and possibly more)
    //
    if (SPECIES_PAGE) {
        out.println("<!--\nDetermined this page is a species page; checking for Red List status ...");
        CmsCategoryService cs = CmsCategoryService.getInstance();
        List<CmsCategory> requestFileCategories = cs.readResourceCategories(cmso, requestFileUri);
        if (requestFileCategories != null && !requestFileCategories.isEmpty()) {
            Iterator<CmsCategory> iCats = requestFileCategories.iterator();
            while (iCats.hasNext()) {
                CmsCategory cat = iCats.next();
                out.print(" - evaluating " + cat.getTitle() + " (" + cat.getPath() + ") ... ");
                //if (cat.getTitle().equalsIgnoreCase(TITLE_RED_LIST_STATUS)) {
                if (cat.getPath().startsWith(RED_LIST_STATUS_PATH) && !cat.getPath().equals(RED_LIST_STATUS_PATH)) {
                    out.println("this IS a Red List status category.");
                    // This is a sub-category of the "Red List status" category, i.e. a specific Red List status (e.g. "Endangered")
                    redListStatus = cat.getTitle();
                    break;
                } else {
                    out.println("this IS NOT a Red List status category.");
                }
            }
        }
        out.println("Done checking categories, Red List status for this species is " + (redListStatus == null ? "undefined" : redListStatus) + ".\n-->");
    }
    */
    /*
    if (CmsAgent.elementExists(author)) {
        author = CmsAgent.removeUsername(author);
        byline = "<div class=\"byline\">" + LABEL_BY + " ";
        byline += CmsAgent.elementExists(authorMail) ? ("<a href=\"mailto:" + authorMail + "\">" + author + "</a>") : author;
        //byline += " &ndash; " + LABEL_LAST_MODIFIED.toLowerCase() + " " + dFormat.format(modifiedDate);
        byline += "</div>";
        if (CmsAgent.elementExists(authorMail))
            byline = CmsAgent.obfuscateEmailAddr(byline, false);
    }
    */
    if (CmsAgent.elementExists(pageTitle)) {
        if (cms.elementExists(imgUri)) {
        %>


        <section class="article-hero">
            <div class="article-hero-content">
                <h1><%= pageTitle %></h1>
                <figure>
                    <!--<img src="<%= cms.link(imgUri) %>" alt="" />-->
                    <%= ImageUtil.getImage(cms, imgUri) %>
                    <figcaption><%= cms.property("byline", imgUri, "") %></figcaption>
                </figure>            
            </div>
        </section>
        <%
        } else {
        %>
        <h1><%= pageTitle %></h1>
        <%
        }
    }
    if (byline != null)
        out.println(byline);
    /*
    if (redListStatus != null) 
        out.println("<div class=\"redlist-status\"><p>" + TITLE_RED_LIST_STATUS + ": " + redListStatus + "</p></div>");
    */
    if (CmsAgent.elementExists(pageIntro)) {
        try { pageIntro = cnr.resolve(pageIntro); } catch (Exception e) {}
        %>
        <section class="descr" id="page-summary"><%= pageIntro %></section><!-- .ingress -->
        <%
    }

    //
    // Paragraphs, handled by a separate file
    //
    cms.include(PARAGRAPH_HANDLER);
    
    // Extension
    if (includeFile != null && wrapInclude) {
        out.println("<!-- Extension found (wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }
    
    
    cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-reflist.jsp");
    
    
    //out.println("</article><!-- .main-content -->");
    out.println("<aside id=\"\" class=\"related\">");
    
    //
    // Pre-defined and generic link lists, handled by a separate file
    //
    cms.include(LINKLIST_HANDLER);
    out.println("</aside><!-- #rightside -->");
    
    
    
    
    /* // REMOVED <div class="page">
    // If the include file should NOT be wrapped inside the ivorypage content div
    if (!wrapInclude)
        out.println("</div><!-- .page -->");
    */

    // Include file from property "template-include-file"
    if (includeFile != null && !wrapInclude) {
        out.println("<!-- Extension found (don't wrap inside): '" + includeFile + "' -->");
        cms.includeAny(includeFile, "resourceUri");
    }
    /* // REMOVED <div class="page">
    // If the include should be wrapped inside the ivorypage content div
    if (wrapInclude)
        out.println("</div><!-- .page (or script div) -->");
    */

} // While container.hasMoreContent()

cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-pageindex.jsp");

//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>