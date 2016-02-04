<%-- 
    Document   : mosj
    Description: MOSJ master template.
    Created on : Dec 10, 2014, 1:28:30 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
                org.opencms.db.CmsResourceState,
                org.opencms.flex.CmsFlexController,
		java.util.*,
                java.text.SimpleDateFormat,
                java.text.DateFormat,
                no.npolar.common.menu.*,
                no.npolar.util.CmsAgent,
                no.npolar.util.contentnotation.*"
                session="true" 
                contentType="text/html" 
                pageEncoding="UTF-8"
%><%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

// Redirect HTTPS requests to HTTP for any non-logged in user
if (!loggedInUser && cms.getRequest().isSecure()) {
    String redirAbsPath = "http://" + request.getServerName() + cms.link(requestFileUri);
    String qs = cms.getRequest().getQueryString();
    if (qs != null && !qs.isEmpty()) {
        redirAbsPath += "?" + qs;
    }
    //out.println("<!-- redirect path is '" + redirAbsPath + "' -->");
    CmsRequestUtil.redirectPermanently(cms, redirAbsPath);
}

Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();
String description          = CmsStringUtil.escapeHtml(CmsHtmlExtractor.extractText(cms.property("Description", requestFileUri, ""), "utf-8"));
String title                = cms.property("Title", requestFileUri, "");
String titleAddOn           = cms.property("Title.addon", "search", "");
//String feedUri              = cms.property("rss", requestFileUri, "");
boolean portal              = Boolean.valueOf(cms.property("portalpage", requestFileUri, "false")).booleanValue();
String canonical            = null;
String featuredImage        = cmso.readPropertyObject(requestFileUri, "image.thumb", false).getValue(null);
String includeFilePrefix    = "";
String fs                   = null; // font size
HttpSession sess            = request.getSession();
String siteName             = cms.property("sitename", "search", cms.label("label.np.sitename"));
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
//boolean pinnedNav           = false; 
boolean homePage            = false;

// Enable session-stored "hover box" resolver
ContentNotationResolver cnr = new ContentNotationResolver();
try {
    // Load global notations
    cnr.loadGlobals(cms, "/" + cms.getRequestContext().getLocale() + "/_global/tooltips.html");
    cnr.loadGlobals(cms, "/" + cms.getRequestContext().getLocale() + "/_global/references.html");
    sess.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
} catch (Exception e) {
    out.println("<!-- Content notation resolver error: " + e.getMessage() + " -->");
}

homePage = requestFileUri.equals("/" + loc + "/") 
            || requestFileUri.equals("/" + loc + "/index.html")
            || requestFileUri.equals("/" + loc + "/index.jsp");




// Handle case: canonicalization
// - Priority 1: a canonical URI is specified in the "canonical" property
// - Priority 2: the current request URI is an index file
CmsProperty propCanonical = cmso.readPropertyObject(requestFileUri, "canonical", false);
// First examine the "canonical" property
if (!propCanonical.isNullProperty()) {
    canonical = propCanonical.getValue();
    if (canonical.startsWith("/") && !cmso.existsResource(canonical))
        canonical = null;
}
// If no "canonical" property was found, and we're displaying an index file,
// set the canonical URL to the folder (remove the "index.html" part).
if (canonical == null && CmsRequestUtil.getRequestLink(requestFileUri).endsWith("/index.html")) {
    canonical = cms.link(requestFolderUri);
    // Keep any parameters
    if (!request.getParameterMap().isEmpty()) {
        // Copy the parameter map. (Since we may need to remove some parameters.)
        Map requestParams = new HashMap(request.getParameterMap());
        // Remove internal OpenCms parameters (they start with a double underscore) 
        // and any other unwanted ones - e.g. font size parameters
        Set keys = requestParams.keySet();
        Iterator iKeys = keys.iterator();
        while (iKeys.hasNext()) {
            String key = (String)iKeys.next();
            if (key.startsWith("__")) // This is an internal OpenCms parameter ...
                iKeys.remove(); // ... so go ahead and remove it.
        }
        if (!requestParams.isEmpty())
            canonical = CmsRequestUtil.appendParameters(canonical, requestParams, true);
    }
}

if (request.getParameter("__locale") != null) {
    locale = new Locale(request.getParameter("__locale"));
    cms.getRequestContext().setLocale(locale);
}
if (request.getParameter("includeFilePrefix") != null) {
    includeFilePrefix = request.getParameter("includeFilePrefix");
}

if (!portal) {
    try {
        if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId())
            portal = true;
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Portal page module not installed
    }
}

String[] moreMarkupResourceTypeNames = { 
                                            "np_event"
                                            , "gallery"
                                            , "np_form"
                                            , "faq"
                                            //, "person"
                                            //, "np_eventcal"
                                        };
// Add those filetypes that require extra markup from this template 
// (These will be wrapped in <article class="main-content">)
List moreMarkupResourceTypes= new ArrayList();
for (int iResTypeNames = 0; iResTypeNames < moreMarkupResourceTypeNames.length; iResTypeNames++) {
    try {
        moreMarkupResourceTypes.add(OpenCms.getResourceManager().getResourceType(moreMarkupResourceTypeNames[iResTypeNames]).getTypeId());
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Resource type not installed
    }
}

// Handle case:
// - Title set as request attribute
if (request.getAttribute("title") != null) {
    try {
        String reqAttrTitle = (String)request.getAttribute("title");
        //out.println("<!-- set title to '" + reqAttrTitle + "' (found request attribute) -->");
        if (!reqAttrTitle.isEmpty()) {
            title = reqAttrTitle;
        }
    } catch (Exception e) {
        // The title found as request attribute was not of type String
    }
    
}

// Handle case: 
// - the current request URI points to a folder
// - the folder has no title
// - the folder's index file has a title (this is the displayed file, so show that title)
//if (title.isEmpty() && (requestFileUri.endsWith("/") || requestFileUri.endsWith("/index.html"))) {
if (title != null && title.isEmpty()) {
    if (requestFileUri.endsWith("/")) {
        title = cmso.readPropertyObject(requestFileUri.concat("index.html"), "Title", false).getValue("");
    }
}

//boolean isFrontPage = false;
//try { isFrontPage = title.equals(siteName); } 
//catch (Exception e) {}

// Insert the "add-on" to the title. For example: A big event has multiple
// pages, and to make the titles unique, the event name could be used as a title add-on.
// Instead of "Programme - NPI", the title would be "Programme - <event name> - NPI"
if (titleAddOn != null && !titleAddOn.equalsIgnoreCase("none") && !titleAddOn.isEmpty()) {
    title = title.concat(" - ").concat(titleAddOn);
}

if (!homePage) {
    title = title.concat(" - ").concat(siteName);
} else {
    title = siteName;
}

title = CmsHtmlExtractor.extractText(title, "utf-8");

// Done with the title. Now create a version of the title specifically targeted at social media (facebook, twitter etc.)
String socialMediaTitle = title.endsWith((" - ").concat(siteName)) ? title.replace((" - ").concat(siteName), "") : title;
// Featured image set? (Also for social media.)
//featuredImage = cmso.readPropertyObject(requestFileUri, "image.thumb", false).getValue(null);

final String NAV_MAIN_URI       = "/" + loc + "/menu.html";
final String LANGUAGE_SWITCH    = "/system/modules/no.npolar.common.lang/elements/sibling-switch.jsp";
final String HOME_URI           = cms.link("/" + loc + "/");
final String SERP_URI           = cms.link("/" + loc + "/" + (loc.equalsIgnoreCase("no") ? "sok" : "search") + ".html");
final String LABEL_CHART_ERROR  = loc.equalsIgnoreCase("no") ? 
                                    ("Kan ikke vise grafen.</p><p class=\"placeholder-element-text-extra\">Prøv å laste inn siden på nytt."
                                        + " Du kan også <a href=\"/om/kontakt.html\">sende oss en feilmelding</a> hvis denne feilen vedvarer.") 
                                    : 
                                    ("Unable to display chart.</p><p class=\"placeholder-element-text-extra\">Try reloading the page."
                                        + " Please <a href=\"/about/contact.html\">report this error</a> should the problem persist.");
final boolean EDITABLE_MENU     = true;
final String NEWSLETTER_URI     = loc.equalsIgnoreCase("no") ? "/en/about/newsletter.html" : "/no/om/nyhetsbrev.html";
final String CTA_NEWSLETTER     = "<a class=\"cta\" id=\"signup-nl\" href=\"" + cms.link(loc.equalsIgnoreCase("no") ? "/no/om/nyhetsbrev.html" : "/en/about/newsletter.html") + "\">"
                                    + "<i class=\"icon-megaphone\"></i> "
                                    + (loc.equalsIgnoreCase("no") ? "Nyhetsbrev" : "Newsletter")
                                    + "</a>";

String menuTemplate = null;
HashMap params = null;
//String quickLinksTemplate = null;
//HashMap quickLinksParams = null;

//String menuFile = cms.property("menu-file", "search", "");

cms.editable(false);

%><cms:template element="head"><!DOCTYPE html>
<html lang="<%= locale.getLanguage() %>">
<head>
<title><%= title %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=0.5,user-scalable=yes" />
<% 
// Print all alternate languages (including current language) for this page
cms.include("/system/modules/no.npolar.common.lang/elements/alternate-languages.jsp"); 
if (canonical != null) 
    out.println("<link rel=\"canonical\" href=\"" + canonical + "\" />");
%>
<meta property="og:title" content="<%= socialMediaTitle %>" />
<meta property="og:site_name" content="<%= siteName %>" />
<%
if (!description.isEmpty()) {
    out.println("<meta name=\"description\" content=\"" + description + "\" />");
    out.println("<meta property=\"og:description\" content=\"" + description + "\" />");
    out.println("<meta name=\"twitter:card\" content=\"summary\" />");
    out.println("<meta name=\"twitter:title\" content=\"" + socialMediaTitle + "\" />");
    out.println("<meta name=\"twitter:description\" content=\"" + CmsStringUtil.trimToSize(description, 180, 10, " ...") + "\" />");
    if (featuredImage != null || cmso.existsResource(featuredImage)) {
        out.println("<meta name=\"twitter:image:src\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:300,h:300,t:3,q:100")) + "\" />");
        out.println("<meta name=\"og:image\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:400,h:400,t:3,q:100")) + "\" />");
    }
}
if (canonical != null) {
    out.println("<meta property=\"og:url\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, canonical) + "\" />");
}
%>
<link rel="apple-touch-icon" sizes="57x57" href="/apple-icon-57x57.png">
<link rel="apple-touch-icon" sizes="60x60" href="/apple-icon-60x60.png">
<link rel="apple-touch-icon" sizes="72x72" href="/apple-icon-72x72.png">
<link rel="apple-touch-icon" sizes="76x76" href="/apple-icon-76x76.png">
<link rel="apple-touch-icon" sizes="114x114" href="/apple-icon-114x114.png">
<link rel="apple-touch-icon" sizes="120x120" href="/apple-icon-120x120.png">
<link rel="apple-touch-icon" sizes="144x144" href="/apple-icon-144x144.png">
<link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152x152.png">
<link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
<link rel="icon" type="image/png" sizes="192x192"  href="/android-icon-192x192.png">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="96x96" href="/favicon-96x96.png">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
<link rel="manifest" href="/manifest.json">
<meta name="msapplication-TileColor" content="#ffffff">
<meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
<meta name="theme-color" content="#ffffff">
<%
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_CSS, requestFileUri));
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_HEAD_SNIPPET, requestFileUri));
%>
<!--<link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Old+Standard+TT:400,700,400italic|Vollkorn:400,700,400italic,700italic|Arvo:400,700italic,400italic,700" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/navigation" + (loggedInUser ? "" : ".min") + ".css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/base" + (loggedInUser ? "" : ".min") + ".css") %>" />
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/base" + (loggedInUser ? "" : ".opt") + ".css") %>" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/smallscreens" + (loggedInUser ? "" : ".min") + ".css") %>" media="(min-width:310px)" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/largescreens" + (loggedInUser ? "" : ".min") + ".css") %>" media="(min-width:801px)" />
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/nav-off-canvas.css") %>" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/print.css") %>" media="print" />
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css") %>" />-->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/modernizr.js") %>"></script>
<!--[if lt IE 9]>
     <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<![endif]-->
<!--[if gte IE 9]><!-->
     <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<!--<![endif]-->
<!--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>-->
<!--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.util/resources/js/stackblur.min.js") %>"></script>-->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/commons.js") %>"></script>
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/nav-off-canvas.js") %>"></script>-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js") %>"></script>-->
<!--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/webfont/1.4.7/webfont.js"></script>-->

<!--[if lte IE 8]>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.util/resources/js/html5.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.util/resources/js/XXXXXXXXXXXrem.min.js") %>"></script>
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/non-responsive-dynamic.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/ie8.css") %>" />
<![endif]-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.hoverintent-1-8-0.min.js") %>"></script>--> 
<style type="text/css">
    html, body { height: 100%; width: 100%; margin: 0; padding: 0; }
    #body { overflow:hidden; }
    .jsready .wcag-off-screen { position:absolute; margin-left:-9999px; }
</style>
</head>
<body id="<%= homePage ? "homepage" : "sitepage" %>"><div id="wrapwrap"><div id="wrap">
    <a id="skipnav" tabindex="1" href="#contentstart"><%= cms.labelUnicode("label.mosj.global.skip-to-content") %></a>
    <div id="jsbox"></div>
    <div id ="top">
        <header id="header" class="no">

            <div id="header-mid" class="clearfix">
                <div class="fullwidth-centered">

                    <a id="identity" href="<%= HOME_URI %>" tabindex="2">
                        <!--<img src="<cms:link>/system/modules/no.npolar.mosj/resources/style/logo-seapop.png</cms:link>" alt="" />-->
                        <img src="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/logo-mosj.png") %>" alt="MOSJ" />
                        <!--<span id="identity-text">MOSJ<span id="identity-tagline">Miljøovervåking Svalbard og Jan Mayen</span></span>-->
                        <span id="identity-text"><%= cms.labelUnicode("label.mosj.global.sitename") %></span>
                    </a>

                    <!-- navigation + search togglers (small screen) -->
                    <a id="toggle-nav" class="nav-toggler" tabindex="6" href="#nav"><span><span></span></span></a>
                    <a id="toggle-search" class="smallscr-only" tabindex="3" href="#search-global"><i class="icon-search"></i></a>
                    <%
                    try { cms.include(LANGUAGE_SWITCH); } catch (Exception e) { out.println("\n<!-- error including language switch: " + e.getMessage() + "\n-->"); }
                    %>
                    <!--
                    <div id="search-global">
                        <form method="get" action="<%= SERP_URI %>">
                            <label for="query" class="hidden"><%= cms.labelUnicode("label.mosj.global.search") %></label>
                            <input type="search" class="query" name="query" id="query" tabindex="4" placeholder="<%= cms.labelUnicode("label.mosj.global.search") %>&hellip;" />
                            <button title="<%= cms.labelUnicode("label.mosj.global.search.submit") %>" type="submit" class="submit" value="" tabindex="5"><i class="icon-search"></i></button>
                        </form>
                    </div>
                    -->
                    <!-- new version -->
                    <div id="search-global" class="searchbox global-site-search">
                        <form method="get" action="<%= SERP_URI %>">
                            <label for="query" class="hidden"><%= cms.labelUnicode("label.mosj.global.search") %></label>
                            <input type="search" class="query query-input" name="query" id="query" placeholder="<%= cms.labelUnicode("label.mosj.global.search.placeholder") %>" />
                            <button class="search-button" title="<%= cms.labelUnicode("label.mosj.global.search.submit") %>" onclick="submit()"><i class="icon-search"></i></button>
                        </form>
                    </div>
                    <!-- end new version -->
                    
                    <!--<a id="toggle-lang" class="smallscr-only" tabindex="" href="javascript:void(0);"><i class="icon-cog"></i></a>

                    <nav id="nav-lang">
                        <ul><li><a class="lang" href="#" hreflang="en">English</a></li><li><a href="#" hreflang="no">Norsk</a></li></ul>
                    </nav>
                    -->
                </div>
            </div>

        </header> <!-- #header -->
    
        <!-- main menu -->
        <div id="navwrap" class="clearfix">
            
            <nav id="nav" role="navigation" class="not-nav-colorscheme-dark">
                <!--<a href="javascript:void(0);" id="close-nav">x</a>-->
                <a class="nav-toggler" id="hide-nav" href="#nonav">Skjul meny</a>
                <%                
                // Get the path to the menu file and put it in a parameter map
                params = new HashMap();
                params.put("filename", NAV_MAIN_URI);
                // Read the property "template-elements" from the menu file. This is the path to the menu template file.
                try {
                    menuTemplate = cms.getCmsObject().readPropertyObject(NAV_MAIN_URI, "template-elements", false).getValue();
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to read the template for the menu '" + NAV_MAIN_URI + "': " + e.getMessage() + " -->");
                }
                try {
                    cms.include(menuTemplate, "full", EDITABLE_MENU, params);
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to include main navigation (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                }
                %>
            </nav>
            
        </div><!-- #navwrap -->
    
        <!-- Breadcrumb navigation: -->
        <nav id="nav_breadcrumb_wrap">
            <%
            // Include the "breadcrumb" element of the menu template file, pass parameters
            try {
                cms.include(menuTemplate, "breadcrumb", EDITABLE_MENU, params);
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to include the breadcrumb menu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
            }
            %>
        </nav>
        <!-- Done with breadcrumb navigation -->
            
    </div><!-- #top -->
    
    <!--<div id="docwrap" class="clearfix">-->
    <!--<div id="mainwrap">-->
        
        <!--<div id="leftside" style="display:none;"></div>-->
        <!--<div id="content" style="width:100%;">-->
            
            
    <a id="contentstart"></a>
    <article class="main-content<%= (portal ? " portal" : "") %>">
</cms:template>
            
<cms:template element="contentbody">
	<cms:include element="body" />
</cms:template>
            
<cms:template element="foot">
    </article>
        <!--</div>--><!-- #content -->        
    <!--</div>--><!-- #mainwrap -->
    <!--</div>--><!-- #docwrap -->
    
    <footer id="footer">
        <aside class="partner-logos">
            <%= cms.getContent("/"+loc+"/partner-logos.txt") %>
        </aside>
        <div id="footer-content">
            <div class="clearfix double layout-group">
                <div class="clearfix boxes">
                    <% if (loc.equalsIgnoreCase("no")) { %>
                    <p><%= CTA_NEWSLETTER %></p>
                    <% } %>
                    <p><%= cms.labelUnicode("label.mosj.global.foot") %></p>
                </div>
            </div>
        </div>
    </footer>
    
    </div></div><!-- wrappers -->
<script type="text/javascript">
function warnOldBrowsers() {
    // Procedure to warn users on MSIE v8 and older
    if (nonResIE()) {
        /*if (!String.prototype.trim) {
            (function() {
                // Make sure we trim BOM and NBSP
                var rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g;
                String.prototype.trim = function() {
                    return this.replace(rtrim, '');
                };
            })();
        }*/
        var warningWasDisplayedCookieId = "browserWarningIssued=true";
        var warningWasDisplayedCookie = warningWasDisplayedCookieId + "; path=/; domain=mosj.no";
        var foundCookie = 0;
        // Get all the cookies from this site and store in an array   
        var cookieArray = document.cookie.split(';');
        
        for (var i=0; i < cookieArray.length; i++) {
            //var checkCookie = cookieArray[i].trim();
            var checkCookie = cookieArray[i];
            //console.log('checking cookie "' + checkCookie + '" ...');
            if (checkCookie.indexOf(warningWasDisplayedCookieId) > -1) {
                foundCookie = 1;
                //console.log('Found cookie, no warning will be presented.');
            }   
        }   
        // Check if a cookie has been found   
        if (foundCookie === 0) {
            //console.log('Cookie not found, issuing one-time message ...');
            // The key_value cookie was not found so set it now   
            document.cookie = warningWasDisplayedCookie;
            $('body').append('<div class="hang-on" id="browserwarn" style="position:fixed; left:0; right:0; top:0; bottom:0; width:100%; height:100%; z-index:9999;">'
                                + '<div class="warn" style="margin:20% auto; background: #fdd; padding:2em; text-align: center; border:1em solid red">'
                                    + '<%= cms.getContent("/"+loc+"/browserwarn.txt").replaceAll("\\'", "\\\\'").replace("\n", "").replace("\r", "") %>'
                                + '</div>'
                            + '</div>');
            $('#browserwarn-ok').click( function() { $('#browserwarn').remove(); } );
            //console.log('Cookie should now be set.');
        }
    }
}

/*
// !!! FONT LOADING moved to base.css !!!
WebFont.load({
    google: {
        families: ['Open+Sans:400,300,700,800,300italic,400italic,700italic,800italic:latin']
        //families: ['Open Sans']
        //families: ['Open Sans', 'Droid Serif', 'Playfair Display']
        //families: ['Old Standard TT', 'Open Sans', 'Droid Sans', 'Droid Serif']
    }
});*/
      

//var large = getSmallScreenBreakpoint();
/*var bigScreen = true;  // Default: Browsers with no support for matchMedia (like IE9 and below) will use this value
try {
    bigScreen = window.matchMedia('(min-width: ' + getSmallScreenBreakpoint() + 'px)').matches; // Update value for browsers supporting matchMedia
} catch (err) {
    // Retain default value
}*/

$(document).ready(function() {
    // Issue warning to users with obsolete browsers
    warnOldBrowsers();
    
    // Prepare Highslide (if necessary)
    readyHighslide('<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.min.css") %>', 
                    '<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.js") %>');
    
    // Replace the identity image (header logo) with SVG version
    if (isBigScreen()) {
        $('.svg #identity > img').attr('src', '<%= cms.link("/system/modules/no.npolar.mosj/resources/style/logo-mosj.svg") %>');
    } else {
        //alert('smallscreen mode ...');
    }
    
    // Blurry hero image background
    if ($('.article-hero')[0]) {
        makeBlurryHeroBackground('<%= cms.link("/system/modules/no.npolar.util/resources/js/stackblur.min.js") %>');
    }
    
    // qTip tooltips
    makeTooltips('<%= cms.link("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css") %>',
                    '<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js") %>');
                    
    // Track clicks
    $('#identity').click(function() {
        try { ga('send', 'event', 'UI interactions', 'clicked site navigation', 'identity area'); } catch(ignore) {}
    });
    $('#nav_topmenu > li:first-child').click(function() {
        try { ga('send', 'event', 'UI interactions', 'clicked site navigation', 'home link in menu'); } catch(ignore) {}
    });
    $('#toggle-nav').click(function() {
        try { ga('send', 'event', 'UI interactions', 'clicked menu toggler', (smallScreenMenuIsVisible() ? 'opened menu' : 'closed menu')); } catch(ignore) {}
    });
    // Newsletter link in footer
    $('#signup-nl').click(function(e) {
        try { ga('send', 'event', 'CTAs', 'clicked newsletter link', 'footer'); } catch(ignore) {}
    });
    // Newsletter signup "submit" button
    $('#mc-embedded-subscribe').click(function() {
        try { ga('send', 'event', 'CTAs', 'clicked to subscribe to newsletter', ''); } catch(ignore) {}
    });
    /*
    $('#mc_embed_signup form').submit(function() {
        try {
            // Indicate progress by fading out form fields
            $("#mc_embed_signup .mc-field-group").fadeTo(500, 0.3);
            $("#mc_embed_signup .mc-field-group input").attr("disabled", "disabled");

            // Clear any existing response field(s)
            $("#mce-responses .response").each(function() {
                $(this).css({"display":"none"});
                $(this).html("");
            });

            // Fire event when a response from the newsletter service is received
            setInterval( function () {
                try {
                    $("#mce-responses .response").each(function() {
                        if ( $(this).html().length ) {
                            $(this).trigger("responseReceived");
                        }
                    });
               } catch (ignore) {}
            }, 100);

            // Listen for response
            $("#mce-responses .response").bind("responseReceived", function() {
                $("#mc_embed_signup .mc-field-group").fadeTo(100, 1);
                $("#mc_embed_signup .mc-field-group input").removeAttr("disabled");
            });
            console.log("Hooked into MC form events.");
        } catch(ignore) {
            console.log("error hooking into MC form events: " + ignore);
        }
    });
    */
    /*
    // Newsletter signup + modal dialog
    $('#signup-nl').click(function(e) {
        e.preventDefault();
        try { ga('send', 'event', 'UI interactions', 'clicked newsletter signup', 'footer'); } catch(ignore) {}
        $('head link').first().before('<link rel="stylesheet" type="text/css" href="//cdn-images.mailchimp.com/embedcode/classic-081711.css" />');
        $('body').append('<div class="overlay overlay--completely" id="signup-nl-bg"><div class="dialog--modal" id="signup-nl-dialog"></div></div>');
        
        
        $('#signup-nl-dialog').load('<%= NEWSLETTER_URI %> #mc_embed_signup', function(response, status, xhr) {
            if (status === 'success') {
                try { ga('send', 'pageview', '<%= NEWSLETTER_URI %>'); } catch (ignore) {}
                $.getScript("//s3.amazonaws.com/downloads.mailchimp.com/js/mc-validate.js", function() {
                    (function($) {
                        window.fnames = new Array();
                        window.ftypes = new Array();
                        fnames[0]='EMAIL';ftypes[0]='email';
                        fnames[1]='FNAME';ftypes[1]='text';
                        fnames[2]='LNAME';ftypes[2]='text';
                        <% if (loc.equalsIgnoreCase("no")) { %>
                        // Translated default messages for the $ validation plugin.
                        // Locale: NO (Norwegian)
                        $.extend($.validator.messages, {
                               required: "Dette feltet er obligatorisk.",
                               maxlength: $.validator.format("Maksimalt {0} tegn."),
                               minlength: $.validator.format("Minimum {0} tegn."),
                               rangelength: $.validator.format("Angi minimum {0} og maksimum {1} tegn."),
                               email: "Oppgi en gyldig e-postadresse.",
                               url: "Angi en gyldig URL.",
                               date: "Angi en gyldig dato.",
                               dateISO: "Angi en gyldig dato (&ARING;&ARING;&ARING;&ARING;-MM-DD).",
                               dateSE: "Angi en gyldig dato.",
                               number: "Angi et gyldig nummer.",
                               numberSE: "Angi et gyldig nummer.",
                               digits: "Skriv kun tall.",
                               equalTo: "Skriv samme verdi igjen.",
                               range: $.validator.format("Angi en verdi mellom {0} og {1}."),
                               max: $.validator.format("Angi en verdi som er mindre eller lik {0}."),
                               min: $.validator.format("Angi en verdi som er st&oslash;rre eller lik {0}."),
                               creditcard: "Angi et gyldig kredittkortnummer."
                        });
                        <% } %>
                    }(jQuery));
                    var $mcj = jQuery.noConflict(true);
                });
            } else if (status === 'error') {
                $('#signup-nl-dialog').html('<p>An error occured</p>');
            }
        });
        //$('#signup-nl-dialog').load('/no/newsletter-signup.html');
        //$('#signup-nl-dialog').load('<%= NEWSLETTER_URI %> #mc_embed_signup');
        $('#signup-nl-bg').click(function(e) {
            // Close the dialog on outside clicks
            if (!($(e.target).closest('#signup-nl-dialog').length)) {
                $(this).remove();
            }
        });
        $('body').bind('keyup', function(e) {
            // Close the dialog on ESC key
            if (e.keyCode === 27) {
                try { $('#signup-nl-bg').remove(); } catch (ignore) {}
            }
        });
    });
    // End newsletter signup + modal dialog
    //*/
});
</script>
<% 
// Enable Analytics 
// (... but not if the "visitor" is actually a logged-in user)
if (!loggedInUser) {
%>
<script type="text/javascript">
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-770196-6', 'auto');
ga('send', 'pageview');
</script>
<script type="text/javascript">
/*
Script: Autogaq 2.1.6 (http://redperformance.no/autogaq/)
Last update: 6 May 2015
Description: Finds external links and track clicks as Events that gets sent to Google Analytics
Compatibility: Google Universal Analytics
*/
!function(){function a(a){var c=a.target||a.srcElement,f=!0,i="undefined"!=typeof c.href?c.href:"",j=i.match(document.domain.split(".").reverse()[1]+"."+document.domain.split(".").reverse()[0]);if(!i.match(/^javascript:/i)){var k=[];if(k.value=0,k.non_i=!1,i.match(/^mailto\:/i))k.category="contact",k.action="email",k.label=i.replace(/^mailto\:/i,""),k.loc=i;else if(i.match(d)){var l=/[.]/.exec(i)?/[^.]+$/.exec(i):void 0;k.category="download",k.action=l[0],k.label=i.replace(/ /g,"-"),k.loc=e+i}else i.match(/^https?\:/i)&&!j?(k.category="outbound traffic",k.action="click",k.label=i.replace(/^https?\:\/\//i,""),k.non_i=!0,k.loc=i):i.match(/^tel\:/i)?(k.category="contact",k.action="telephone",k.label=i.replace(/^tel\:/i,""),k.loc=i):f=!1;f&&(a.preventDefault(),g=k.loc,h=a.target.target,ga("send","event",k.category.toLowerCase(),k.action.toLowerCase(),k.label.toLowerCase(),k.value,{nonInteraction:k.non_i}),b())}}function b(){"_blank"==h?window.open(g,"_blank"):window.location.href=g}function c(a,b,c){a.addEventListener?a.addEventListener(b,c,!1):a.attachEvent("on"+b,function(){return c.call(a,window.event)})}var d=/\.(zip|exe|dmg|pdf|doc.*|xls.*|ppt.*|mp3|txt|rar|wma|mov|avi|wmv|flv|wav)$/i,e="",f=document.getElementsByTagName("base");f.length>0&&"undefined"!=typeof f[0].href&&(e=f[0].href);for(var g="",h="",i=document.getElementsByTagName("a"),j=0;j<i.length;j++)c(i[j],"click",a)}();
</script>
<script type="text/javascript">
/*
Script: Still here beacon (Based on http://redperformance.no/google-analytics/time-on-site-manipulasjon/)
Last update: 3 Nov 2015
Description: Sends an event to Google Analytics every N seconds after the page has loaded, to improve time-on-site metrics.
    Works like a beacon, regularly signaling that the visitor is "still here".
    By changing nonInteraction to false, beacon beeps are treated as interactions. The most notable effect 
    of this will be that any visit that produces at least one beacon beep will not be considered a bounce.
Compatibility: Google Universal Analytics
*/
var secondsOnPage = 0; // How many (active) seconds the user has spent on this page
var pageVisible = true; // Flag that indicates whether or not the page is visible, see http://www.samdutton.com/pageVisibility/
var beaconInterval = 10; // Frequency at which to send the beacon signal (in seconds)
function handleVisibilityChange() {
    try {
        if (document['hidden']) {
            pageVisible = false;
        } else {
            pageVisible = true;
        }
    } catch (err) {
        pageVisible = true;
    }
}
// Set initial page visibility flag
handleVisibilityChange();
// Set the visibility change handler
document.addEventListener('visibilitychange', handleVisibilityChange, false);
// Initialize counter and beacon signal
window.setInterval(
    function() {
        try {
            if (pageVisible) {
                if (++secondsOnPage % beaconInterval === 0) {
                    ga('send', 'event', 'seconds on page', 'log', secondsOnPage, {nonInteraction: true});
                }
            }
        } catch (ignore) { }
    }, 1000);
</script>
<% 
}
// Make the Highcharts charts, if necessary, by
// 1. loading HighCharts scripts asynchronyously
// 2. printing out all the javascript for charts on this page
Map<String, String> hcConfs = null;
try { hcConfs = (Map<String, String>)cms.getRequest().getAttribute("hcConfs"); } catch (Exception e) {}

if (hcConfs != null && !hcConfs.isEmpty()) {
%>
<script type="text/javascript">
$(document).ready(function(){
    $(function () {
        $.getScript('<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/highcharts.js") %>', function() {
            $.getScript('<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/highcharts-more.js") %>', function() {
                $.getScript('<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/modules/data.js") %>', function() {
                    $.getScript('<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/modules/exporting.js") %>', function() {
                        Highcharts.theme = getHighchartsTheme('<%= loc %>');
                        Highcharts.setOptions(Highcharts.theme);
                        <%
                        Iterator<String> iHcConfs = hcConfs.keySet().iterator();
                        while (iHcConfs.hasNext()) {
                            String chartWrapper = iHcConfs.next();
                            String chartConfig = hcConfs.get(chartWrapper);
                        %>
                        try {
                            $('#<%= chartWrapper %>').highcharts(<%= chartConfig %>);
                        } catch (err) {
                            //console.log('Something went wrong: ' + err);
                            $('#<%= chartWrapper %> > .placeholder-element').addClass('placeholder-element-error').find('.placeholder-element-text').html('<p><%= LABEL_CHART_ERROR %></p>');
                        }
                        <%
                        
                        }
                        %>
                    });
                });
            });
        });
    });
});
</script>
<%
cms.getRequest().removeAttribute("hcConfs");
}
else {
    out.println("<!-- no chart configurations found (" + (hcConfs == null ? "null" : (hcConfs.isEmpty() ? "empty" : "???")) + ") -->");
}
%>
</body>
</html>
<%
// Clear hoverbox resolver
cnr.clear();
// Clear session variables and hoverbox resolver
sess.removeAttribute("share");
sess.removeAttribute("autoRelatedPages");
sess.removeAttribute(ContentNotationResolver.SESS_ATTR_NAME);
%>
</cms:template>