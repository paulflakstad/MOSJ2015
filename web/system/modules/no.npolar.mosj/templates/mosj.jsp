<%-- 
    Document   : MOSJ master template
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

Locale loc                  = cms.getRequestContext().getLocale();
String locale               = loc.toString();
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
    loc = new Locale(request.getParameter("__locale"));
    cms.getRequestContext().setLocale(loc);
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
//final String MENU_TOP_URL       = includeFilePrefix + "/header-menu.html";
//final String QUICKLINKS_MENU_URI= "/menu-quicklinks-isblink.html";
final String LANGUAGE_SWITCH    = "/system/modules/no.npolar.common.lang/elements/sibling-switch.jsp";
//final String FONT_SIZE_SWITCH   = "/system/modules/no.npolar.site.npweb/elements/font-size-switch.jsp";
//final String FOOTERLINKS        = "/system/modules/no.npolar.site.npweb/elements/footerlinks.jsp";
//final String SEARCHBOX          = "/system/modules/no.npolar.site.npweb/elements/search.jsp";
//final String LINKLIST           = "../../no.npolar.common.linklist/elements/linklist.jsp";
final String HOME_URI           = cms.link("/" + locale + "/");
final String SERP_URI		= cms.link("/" + locale + "/" + (locale.equalsIgnoreCase("no") ? "sok" : "search") + ".html");
final boolean EDITABLE_MENU     = true;

String menuTemplate = null;
HashMap params = null;
//String quickLinksTemplate = null;
//HashMap quickLinksParams = null;

//String menuFile = cms.property("menu-file", "search", "");

cms.editable(false);

%><cms:template element="head"><!DOCTYPE html>
<html lang="<%= loc.getLanguage() %>">
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
<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/webfont/1.4.7/webfont.js"></script>

<!--[if lte IE 8]>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.util/resources/js/html5.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.util/resources/js/XXXXXXXXXXXrem.min.js") %>"></script>
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/non-responsive-dynamic.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.mosj/resources/style/ie8.css") %>" />
<![endif]-->
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.hoverintent-1-8-0.min.js") %>"></script>-->
<% if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId()) { %>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/highcharts.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/highcharts-more.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/modules/data.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.mosj/resources/js/hc/js/modules/exporting.js") %>"></script>
<script type="text/javascript">
    Highcharts.theme = {
        colors: [
            '#0277D5',// bright blue
            '#E52418',// bright red
            '#49A801',// bright green
            '#393331',// asphalt
            '#8E1FAC',// bright purple
            '#C74F18',// orange
            '#7D6F42',// earth
            '#78753E',// olive
            '#CD238E',// bright pink
            '#197d86',// teal
            '#054477',// deep blue
            '#4E0C13' // plum
        ],
        chart: {
            backgroundColor: {
                linearGradient: [0, 0, 500, 500],
                stops: [
                    [0, 'rgb(255, 255, 255)']
                ]
            },
        },
        title: {
            style: {
                color: '#000',
                font: '1.5em "Open sans", "Trebuchet MS", Verdana, sans-serif'
            }
        },
        tooltip: {
            backgroundColor: '#fff',
            borderColor: '#666',
            borderRadius: 5,
            borderWidth: 2
        },
        legend: {
            itemStyle: {
                font: '1em "Open sans", Trebuchet MS, Verdana, sans-serif',
                color: '#000'
            },
            itemHiddenStyle:{
                color: '#aaa'
            } ,
            itemHoverStyle:{
                color: '#000',
                font: 'bold'
            }   
        },
        lang: {
            decimalPoint: '<%= locale.equalsIgnoreCase("no") ? "," : "." %>',
            downloadJPEG: '<%= locale.equalsIgnoreCase("no") ? "Last ned som JPG" : "Download as JPG" %>',
            downloadPNG: '<%= locale.equalsIgnoreCase("no") ? "Last ned som PNG" : "Download as PNG" %>',
            downloadPDF: '<%= locale.equalsIgnoreCase("no") ? "Last ned som PDF" : "Download as PDF" %>',
            downloadSVG: '<%= locale.equalsIgnoreCase("no") ? "Last ned som SVG" : "Download as SVG" %>',
            drillUpText: '<%= locale.equalsIgnoreCase("no") ? "Tilbake til {series.name}" : "Back to {series.name}" %>',
            loading: '<%= locale.equalsIgnoreCase("no") ? "Laster..." : "Loading..." %>',
            printChart: '<%= locale.equalsIgnoreCase("no") ? "Skriv ut figur" : "Print chart" %>',
            resetZoom: '<%= locale.equalsIgnoreCase("no") ? "Nullstill zoom" : "Reset zoom" %>',
            resetZoomTitle: '<%= locale.equalsIgnoreCase("no") ? "Sett zoomnivået til 1:1" : "Reset zoom level to 1:1" %>',
            thousandsSep: '<%= locale.equalsIgnoreCase("no") ? " " : "," %>'
        }
    };
    Highcharts.setOptions(Highcharts.theme);
</script>
<% } %>
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
                    <a id="toggle-search" class="smallscr-only" tabindex="3" href="javascript:void(0);"><i class="icon-search"></i></a>
                    <%
                    try { cms.include(LANGUAGE_SWITCH); } catch (Exception e) {}
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
            
            <nav id="nav" role="navigation" class="nav-colorscheme-dark">
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
        <div id="footer-content">
            <div class="clearfix double layout-group">
                <div class="clearfix boxes">
                    <p><%= cms.labelUnicode("label.mosj.global.foot") %></p>
                </div>
            </div>
        </div>
    </footer>
    
    </div></div><!-- wrappers -->
<script type="text/javascript">
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
</script>
<script type="text/javascript">
WebFont.load({
    google: {
        families: ['Open Sans']
        //families: ['Open Sans', 'Droid Serif', 'Playfair Display']
        //families: ['Old Standard TT', 'Open Sans', 'Droid Sans', 'Droid Serif']
    }
});
      
var width = $(window).width();
var large = getSmallScreenBreakpoint();
var bigScreen = true;  // Default: Browsers with no support for matchMedia (like IE9 and below) will use this value
try {
    bigScreen = window.matchMedia('(min-width: ' + large + 'px)').matches; // Update value for browsers supporting matchMedia
} catch (err) {
    // Retain default value
}

$(document).ready(function() {
    //alert('doc ready');
    initUserControls();
    
    // Prepare Highslide (if necessary)
    readyHighslide('<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.min.css") %>', 
                    '<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.js") %>');
    
    if (bigScreen) {
        $('.svg #identity > img').attr('src', '<%= cms.link("/system/modules/no.npolar.mosj/resources/style/logo-mosj.svg") %>');
    } else {
        //alert('smallscreen mode ...');
    }
    if ($('.article-hero')[0]) {
        // blurry hero image background
        makeBlurryHeroBackground('<%= cms.link("/system/modules/no.npolar.util/resources/js/stackblur.min.js") %>');
    }
    // qTip tooltips
    makeTooltips('<%= cms.link("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css") %>',
                    '<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js") %>');
});

function initUserControls() {
    //if (smallScreenMenuIsVisible) {
        $('#nav').find('li.has_sub').not('.inpath').addClass('hidden-sub');
        $('#nav').find('li.has_sub.inpath').addClass('visible-sub');
        //$('#nav').find('li.has_sub').append('<a class="visible-sub-toggle" href="javascript:void(0)"></a>');
        $('#nav').find('li.has_sub > a').after('<a class="visible-sub-toggle" href="javascript:void(0)"></a>');
        $('.visible-sub-toggle').click(function(e) {
            $(this).parent('li').toggleClass('visible-sub hidden-sub');
        });

        $('.nav-toggler').click(function(e) {
            e.preventDefault();
            $('html').toggleClass('navigating');
        });

        // ToDo: Fix - #docwrap does not exist anymore
        $('#docwrap').click(function() {
            if (smallScreenMenuIsVisible()) {
                $('html').toggleClass('navigating');
            }
        });
    //}
	
    // toggle a "focus" class on the top-level menus when appropriate
    $('#nav a').focus(function() {
        $(this).parents('li').addClass('infocus');
    });
    $('#nav a').blur(function() {
        $(this).parents('li').removeClass('infocus');
    });
    
    if (!Modernizr.touch) {
        // use "hover delay" to add usability bonus
        $('#nav li').hoverDelay({
            delayIn: 250,
            delayOut: 400,
            handlerIn: function($element)   { $element.addClass('infocus'); },
            handlerOut: function($element)  { $element.removeClass('infocus'); }
        });
        /*
        // use hoverintent to add usability bonus for mouse users
        $('#nav li').hoverIntent({
            over: mouseinMenuItem
            ,out: mouseoutMenuItem
            ,timeout:400
            ,interval:250
        });
        */
    } else {
        // Touch units will typically emulate these mouse events
        $('#nav li').mouseover(function()   { $(this).addClass('infocus'); });
        $('#nav li').mouseout(function()    { $(this).removeClass('infocus'); });
    }
    
    // accessibility bonus: clearer outlines
    $('head').append('<style id="behave" />');
    $('body').bind('mousedown', function(e) {
        $('html').removeClass('tabbing');
        mouseFriendly();
    });
    $('body').bind('keydown', function(e) {
        $('html').addClass('tabbing');
        if (e.keyCode === 9) {
            keyFriendly();
        }
    });
    
    // handle clicks on "show/hide search field"
    $('#toggle-search').click(function(e) {	
        var search = $('#search-global');
        search.removeAttr('style');
        $('html').toggleClass('search-open');
        search.toggleClass('not-visible');
        if (!search.hasClass('not-visible')) {
            $('#query').focus();
        }
    });
    
    
    // Clone the language switch and put it in the menu
    if (!$('.language-switch-menu-item')[0]) { // do it only if necessary
        var clonedLangSwitch = $('.language-switch').clone().attr('class', 'language-switch-menu-item').attr('style', '');
        var liLangSwitch = $('<li/>').attr('style', 'border-top:1px solid orange').attr('class', 'smallscr-only').appendTo($('#nav_topmenu'));
        liLangSwitch.append(clonedLangSwitch.prepend('<i class="icon-cog" style="font-size:1.2em;"></i> '));
    }
    $('.language-switch').addClass('bigscr-only');

    // Add resize listener
    $(window).resize(function() {
        // Trigger only on width resize
        if($(this).width() != width) {
            width = $(this).width();
            layItOut();
        }
    });

    layItOut();
}

function mouseinMenuItem(menuItem) {
    $(this).addClass('infocus');
}
function mouseoutMenuItem(menuItem) {
    $(this).removeClass('infocus');
}

function layItOut() {
    var bigScreen = true;
    try {
        bigScreen = window.matchMedia('(min-width: ' + large + 'px)').matches; // Update value for browsers supporting matchMedia
    } catch (err) {
        // Retain default value
    }
    if (bigScreen) {
        // Large viewport

        // Create the large screen submenu: 
        // Clone the current top-level navigation's submenu, add it to the DOM and wrap it in a <nav>
        if (emptyOrNonExistingElement('subnavigation')) { // Don't keep adding the submenu again and again ... Du-uh
            var submenu = $('.inpath.subitems > ul').clone(); // Clone it
            submenu.removeAttr('class').removeAttr('style'); // Strip classes and attributes (which may have been modified by togglers in small screen view)
            submenu.children('ul').removeAttr('class').removeAttr('style'); // Do the same for all deeper levels
            $('#leftside').append('<nav id="subnavigation" role="navigation"><ul>' + submenu.html() + '</ul></nav>');
        }
        $('#nav').removeClass('nav-colorscheme-dark');
        
        $('#search-global').removeClass('not-visible');
        $('#search-global').removeAttr('style');
        
        //$('.language-switch').show();

        // 3rd and deeper level menus
        /*
        $('#nav ul ul li.has_sub').not('.inpath').mouseenter(function() {
                $(this).addClass('subnav-popup');
        });
        $('#nav ul ul li.has_sub').not('.inpath').mouseleave(function() {
            $(this).removeClass('subnav-popup');
        });
        */
        /*$('#nav ul ul li.has_sub').not('.inpath').children('a').first().focus(function() {
            $(this).parents('li').first().addClass('subnav-popup');
        });
        $('#nav ul ul li.has_sub').not('.inpath').children('a').first().blur(function() {
            $(this).parents('li').first().removeClass('subnav-popup');
        });*/
    }
    else {
        $('#nav').addClass('nav-colorscheme-dark');
        
        $('#subnavigation').remove(); // Remove the big screen submenu
        $('#search-global').hide(); // Prevent "search box collapse" animation on page load
        //$('#search-global').attr('style', 'display:none;'); // Prevent search box collapsing animation on page load
        $('#search-global').addClass('not-visible');
    }
}

function keyFriendly() {
    try { 
        document.getElementById("behave").innerHTML="a:focus, input:focus, button:focus, select:focus { outline:thin dotted; outline:3px solid #1f98f6; }"; 
    } catch (err) {}
}
function mouseFriendly() {
    try { 
        document.getElementById("behave").innerHTML="a, a:focus, input:focus, select:focus { outline:none !important; }"; 
    } catch (err) {}
}

function smallScreenMenuIsVisible() {
    return $('html').hasClass('navigating');
}

function showSubMenu() {
}


document.getElementsByTagName('a').onfocus = function(e) {
    this.toggleClass('has-focus');
};
</script>
<% if (!loggedInUser) { %>
<script type="text/javascript">
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-770196-6', 'auto');
ga('send', 'pageview');
</script>
<% } %>
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