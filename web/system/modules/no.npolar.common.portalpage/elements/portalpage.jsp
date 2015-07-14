<%-- 
    Document   : portalpage
    Created on : Nov 16, 2012, 5:58:36 PM
    Author     : flakstad
--%><%-- 
    Document   : portalpage-redesigned
    Created on : Mar 21, 2012, 4:33:31 PM
    Author     : flakstad
--%><%@ page import="no.npolar.util.*,
                 no.npolar.util.contentnotation.*,
                 java.util.Locale,
                 java.util.Date,
                 java.util.Map,
                 java.util.HashMap,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.types.*,
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.util.CmsUUID,
                 org.opencms.util.CmsRequestUtil" session="true" %><%!
                 
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

HashMap<String, String> widthMap = new HashMap<String, String>();
String[] widthClasses = { "", "single", "double", "triple", "quadruple" };
// Common page element handlers
final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler-standalone.jsp";
//final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";
final String LINKLIST_HANDLER       = "../../no.npolar.common.pageelements/elements/linklisthandler.jsp";
final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";
// Image size
final int IMAGE_SIZE_S              = 120;//217;
final int IMAGE_SIZE_M              = 320;
final int IMAGE_SIZE_L              = 500;
final int IMAGE_PADDING             = 4;
// Direct edit switches
final boolean EDITABLE              = false;
final boolean EDITABLE_TEMPLATE     = false;
// Labels
final String LABEL_BY               = cms.labelUnicode("label.np.by");
final String LABEL_LAST_MODIFIED    = cms.labelUnicode("label.np.lastmodified");
final String PAGE_DATE_FORMAT       = cms.labelUnicode("label.np.dateformat.normal");
final String LABEL_SHARE            = cms.labelUnicode("label.np.share");
// Image handle / scaler
CmsImageScaler imageHandle          = null;
CmsImageScaler targetScaler         = new CmsImageScaler();
targetScaler.setWidth(IMAGE_SIZE_S);
targetScaler.setType(1);
targetScaler.setType(4); // Avoid white lines in bottom/right of image
targetScaler.setQuality(100);
// File information variables
int portalWidth                     = 3;
int sectionColspan                  = -1;
// XML content containers
I_CmsXmlContentContainer container  = null;
I_CmsXmlContentContainer heroImage  = null;
I_CmsXmlContentContainer paragraph  = null;
I_CmsXmlContentContainer carousel   = null;
I_CmsXmlContentContainer carouselItems   = null;
I_CmsXmlContentContainer bigSection = null;
I_CmsXmlContentContainer section    = null;
I_CmsXmlContentContainer sectionContent    = null;
I_CmsXmlContentContainer readMore   = null;
// String variables for structured content elements
String pageTitle                    = null;
String pageIntro                    = null;
boolean pageIntroAsOverlay          = false;
String pageIntroStyle               = null;
String shareLinksString             = null;
boolean shareLinks                  = false;
// Template ("outer" or "master" template)
String template                     = cms.getTemplate();
String[] elements                   = null;
try {
    elements = cms.getTemplateIncludeElements();
} catch (Exception e) {
    elements = new String[] { "head", "foot" };
}

//
// Include upper part of main template
//
cms.include(template, elements[0], EDITABLE_TEMPLATE);


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

String htmlCarousel = "";
String htmlCarouselNavi = "";

//
// Process file contents
//
while (container.hasMoreContent()) {
    //out.println("<div class=\"page\">"); // REMOVED <div class="page">
    
    portalWidth = 2;// Integer.valueOf(cms.contentshow(container, "Columns")).intValue();
    //String htmlPortalWrapperClass = "fourcol-equal " + (portalWidth == 3 ? "triple right" : "quadruple");
    //out.println("<div class=\"" + htmlPortalWrapperClass + "\">"); // e.g. <div class="fourcol-equal quadruple">
    
    String heroImageHtml = "";
    heroImage = cms.contentloop(container, "HeroImage");
    while (heroImage.hasMoreResources()) {
        
        ImageUtil figure = new ImageUtil(cms, heroImage);
        heroImageHtml = figure.getImage("", null, 100, 1200, 100, "800px");
        
        /*String heroImageUri = cms.contentshow(heroImage, "URI");
        String heroImageCaption = cms.contentshow(heroImage, "Text");
        String heroImageSource = cms.contentshow(heroImage, "Source");
        
        if (cmso.existsResource(heroImageUri)) {
            heroImageHtml += "<figure>" + ImageUtil.getImage(cms, heroImageUri, null, null, 1200, 100, ImageUtil.SIZE_L, 100, "800px");
            if (CmsAgent.elementExists(heroImageCaption)
                    || CmsAgent.elementExists(heroImageSource)) {
                heroImageHtml += "<figcaption>";
                if (CmsAgent.elementExists(heroImageCaption)) {
                    heroImageHtml += heroImageCaption;
                }
                if (CmsAgent.elementExists(heroImageSource)) {
                    heroImageHtml += "<span class=\"credit\">" 
                                        + cms.labelUnicode("label.pageelements." + cms.contentshow(heroImage, "ImageType").toLowerCase()) 
                                        + ": " + heroImageSource 
                                    + "</span>";
                }
                heroImageHtml += "</figcaption>";
            }
            heroImageHtml += "</figure>";
        }*/
    }
    
    
    pageTitle = cms.contentshow(container, "Title").replaceAll(" & ", " &amp; ");
    pageIntro = cms.contentshow(container, "Intro");
    pageIntroStyle = cms.contentshow(container, "IntroStyle");
    
    try { 
        pageIntroAsOverlay = Boolean.valueOf(cms.contentshow(container, "IntroAsOverlay")).booleanValue();
    } catch (Exception e) {}
    
    shareLinksString= cms.contentshow(container, "ShareLinks");
    if (!CmsAgent.elementExists(shareLinksString))
        shareLinksString = "true"; // Default value if this element does not exist in the file (backward compatibility)

    try {
        shareLinks      = Boolean.valueOf(shareLinksString).booleanValue();
    } catch (Exception e) {
        shareLinks = true; // Default value if above line fails (it shouldn't, but just to be safe...)
    }
    
    
    // Start the left column
    //out.println("<div class=\"fourcol-equal double left\">");
    //out.println("<div class=\"portal left\">");
    //out.println("<article class=\"main-content portal\">");
    
    if (!heroImageHtml.isEmpty()) {
        out.println("<div class=\"article-hero\">");
        out.println("<div class=\"article-hero-content\">");
    }
    // Title and page intro
    if (CmsAgent.elementExists(pageTitle)) {
        out.println("<h1>" + pageTitle + "</h1>");
    }
    
    if (!heroImageHtml.isEmpty()) {
        out.println(heroImageHtml);
        if (CmsAgent.elementExists(pageIntro) && pageIntroAsOverlay) {
            try { pageIntro = cnr.resolve(pageIntro); } catch (Exception e) {}
            out.println("<section class=\"descr overlay\"" + (CmsAgent.elementExists(pageIntroStyle) ? (" style=\""+pageIntroStyle+"\"") : "") + ">" + pageIntro + "</section>");
        }
        out.println("</div><!-- .article-hero-content -->");  
        out.println("</div><!-- .article-hero -->");   
    }
    
    
    if (CmsAgent.elementExists(pageIntro) && !pageIntroAsOverlay) {
        try { pageIntro = cnr.resolve(pageIntro); } catch (Exception e) {}
        out.println("<section class=\"descr\">" + pageIntro + "</section>");
    }
    
    
    // Featured content (carousel)
    carousel = cms.contentloop(container, "Carousel");
    while (carousel.hasMoreContent()) {
        // Image sizes (aspect ratio is 16:9)
        final int CAROUSEL_IMAGE_WIDTH = 1200; //550;
        final int CAROUSEL_IMAGE_HEIGHT = 800; //323;
        htmlCarousel += "<ul id=\"slides\">";
        carouselItems = cms.contentloop(carousel, "CarouselItem");
        int ciCount = 0;
        while (carouselItems.hasMoreContent()) {
            //ciCount++;
            String ciTitle = cms.contentshow(carouselItems, "Title").replaceAll(" & ", " &amp; ");
            String ciText = cms.contentshow(carouselItems, "Text");
            String ciImage = cms.contentshow(carouselItems, "Image");
            String ciLink = cms.contentshow(carouselItems, "Link");
            ciLink = CmsAgent.elementExists(ciLink) ? ciLink : "#".concat(String.valueOf(ciCount));
            //*
            // Scale image if necessary
            CmsImageScaler imageOri = new CmsImageScaler(cmso, cmso.readResource(ciImage));
            
            if (imageOri.getWidth() > CAROUSEL_IMAGE_WIDTH || imageOri.getHeight() > CAROUSEL_IMAGE_HEIGHT) {
                CmsImageScaler reScaler = new CmsImageScaler(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + CAROUSEL_IMAGE_WIDTH + "," + 
                                            CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + CAROUSEL_IMAGE_HEIGHT + "," +
                                            CmsImageScaler.SCALE_PARAM_TYPE + ":" + 2 + "," +
                                            CmsImageScaler.SCALE_PARAM_QUALITY + ":" + 100);
                String imageTag = cms.img(ciImage, reScaler, null);
                //out.println("<!-- cms.img() returned " + imageTag + " -->");
                String imageSrc = (String)CmsAgent.getTagAttributesAsMap(imageTag).get("src");
                ciImage = imageSrc;
            }
            //*/
            
            //htmlCarouselNavi += "\n<em" + (ciCount == 0 ? " class=\"swipe-current-pos\"" : "") + " title=\"" + ciTitle + "\" onclick=\"slider.slide("+ciCount+",300);return false;\">&bull;</em>";
            htmlCarousel += "\n<li class=\"slide\">" +
                                "\n<div class=\"content\">" +
                                    "\n<a href=\"" + ciLink + "\"><img alt=\"" + ciTitle + "\" src=\"" + cms.link(ciImage) + "\" /></a>" +
                                    "\n<div class=\"featured-text overlay\" onclick=\"javascript:window.location = '" + ciLink + "'\">" + 
                                    "\n<h4>" + ciTitle + "</h4>" +
                                        "\n" + ciText + 
                                    "\n</div>" +
                                "\n</div>" +
                            "\n</li>";
            ciCount++;
        }
        
        htmlCarouselNavi += "<nav>"
                                + "<a href=\"#\" id=\"featured-prev\" class=\"prev\"></a>"
                                + "<div class=\"pagination\"></div>"
                                + "<a href=\"#\" id=\"featured-next\" class=\"next\"></a>"
                            + "</nav>";
        htmlCarousel += "\n</ul>";
        
        out.println("<div id=\"featured\" class=\"portal-box\">");
        out.println(htmlCarousel);
        out.println(htmlCarouselNavi);
        out.println("</div><!-- #featured.portal-box -->");
    }
    
    
    /*
    //while (readMore.hasMoreContent()) {
        request.setAttribute("paragraphContainer", container);
        request.setAttribute("paragraphElementName", "ReadMore");
        request.setAttribute("paragraphWrapper", new String[]{"<div class=\"paragraph portal-box\">", "</div><!-- .paragraph.portal-box -->"});
        //if (portalWidth == 4) { // Print it here only if the portal width is "fullwidth" - if not, we'll print it later
            //out.println("<div class=\"portal-box\">");
            cms.include(PARAGRAPH_HANDLER);
            //out.println("</div>");
        //}
    //}
    */
    
    // Print the left side "paragraph" sections
    request.setAttribute("paragraphContainer", container);
    request.setAttribute("paragraphElementName", "BigSection");
    request.setAttribute("paragraphHeadingAttribs", " style=\"margin-top:0;\"");
    //request.setAttribute("paragraphMediaClass", "span2 pull-right");
    request.setAttribute("paragraphWrapper", new String[]{"<section class=\"paragraph clearfix\" id=\"portalpage-first\">", "</section><!-- .test -->"});
    //request.setAttribute("paragraphTextWrapper", new String[]{"<div class=\"span1 pull-left\">", "</div>"});
    
    //out.println("<section class=\"portal-box triple\">");
    cms.include(PARAGRAPH_HANDLER);
    //out.println("</section><!-- .portal-box -->");
    
    
    // End the left column
    //out.println("</div><!-- .column.portal.left -->");
    
    
    
    
    // ###########################################################################
    // ###########################                     ###########################
    // ########################### LEFT / RIGHT DIVIDE ###########################
    // ###########################                     ###########################
    // ###########################################################################
    
    
    
    
    
    // Start the right column
    //out.println("<div class=\"portal right\">");
    
    section = cms.contentloop(container, "Section");
    int sCount = 0;
    boolean initialWrapperEnded = false;
    while (section.hasMoreContent()) {
        sCount++;
        String sectionHeading = cms.contentshow(section, "Heading");
        sectionColspan = Integer.valueOf(cms.contentshow(section, "Columns")).intValue();
        boolean overlayHeadings = Boolean.valueOf(cms.contentshow(section, "OverlayHeadings")).booleanValue();
        boolean boxed = Boolean.valueOf(cms.contentshow(section, "Boxed")).booleanValue();
        boolean textAsHoverBox = Boolean.valueOf(cms.contentshow(section, "TextAsHoverBox")).booleanValue();
        String sectionCssClass = cms.contentshow(section, "CssClass");
        String dynamicContentUri = cms.contentshow(section, "DynamicContent");
        boolean isDynamicContentSection = CmsAgent.elementExists(dynamicContentUri);
                
        // Start the right column
        out.println("<section class=\"clearfix " 
                + (CmsAgent.elementExists(sectionCssClass) ? sectionCssClass.concat(" ") : "")
                + widthClasses[sectionColspan] + " layout-group"  
                + (overlayHeadings ? " overlay-headings" : "")
                + (boxed ? " boxed" : "") 
                + (isDynamicContentSection ? " dynamic" : "")
                + "\">");
        if (CmsAgent.elementExists(sectionHeading)) {
            out.println("<h2 class=\"section-heading\">" + sectionHeading + "</h2>");
        }
        
        if (!isDynamicContentSection) { // Dynamic content must handle wrapping itself
            out.println("<div class=\"boxes clearfix\">");
        }
        
        // "Section content" contains one or multiple instances of "portal-boxes"
        sectionContent = cms.contentloop(section, "Content");
        int scCount = 0; // Section content iteration counter
        if (CmsAgent.elementExists(dynamicContentUri)) {
            // Add parameter describing the container into which the dynamic content will be included
            dynamicContentUri += dynamicContentUri.contains("?") ? "&" : "?";
            dynamicContentUri += "dynamic_container=portal_page_section";
            if (CmsAgent.elementExists(sectionHeading) && !sectionHeading.isEmpty()) {
                // Request to suppress the list's own heading
                dynamicContentUri += "&override_heading=none";
            }
            
            // Set a session variable describing the container into which the dynamic content will be included
            /*cms.getRequest().getSession().setAttribute("dynamic_container", "portal_page_section");
            if (CmsAgent.elementExists(sectionHeading) && !sectionHeading.isEmpty()) // Request to suppress the list's own heading
                cms.getRequest().getSession().setAttribute("override_heading", "none");*/
            
            if (dynamicContentUri.contains("?")) {
                try {
                    //out.println("<!-- portalpage:: Dynamic content found: " + dynamicContentUri + " -->");
                    String scDynamicPath = dynamicContentUri.split("\\?")[0];
                    String scDynamicQuery = dynamicContentUri.split("\\?")[1];
                    //out.println("<!-- portalpage:: Creating parameter map ... -->");
                    Map<String, String[]> scDynamicParams = CmsRequestUtil.createParameterMap(scDynamicQuery);
                    out.println("<!-- portalpage: Ready to include dynamic content '" + scDynamicPath + "' with query '" + scDynamicQuery + "' (" + scDynamicParams.size() + " parameters). -->");
                    try {
                        cms.includeAny(scDynamicPath, null, scDynamicParams);
                    } catch (Exception ee) {
                        //out.println("<!-- Portal page failed to include dynamic content with includeAny(), error was: " + ee.getMessage() + " -->");
                        cms.include(scDynamicPath, null, scDynamicParams);
                    }
                } catch (Exception e) {
                    out.println("<!-- portalpage: failed to include dynamic content, error was: " + e.getMessage() + " -->");
                }
            } else {
                cms.includeAny(dynamicContentUri, "resourceUri");
            }
            // Clear session variables
            /*cms.getRequest().getSession().removeAttribute("dynamic_container");
            cms.getRequest().getSession().removeAttribute("override_heading");*/
        } else {
            while (sectionContent.hasMoreContent()) {
                scCount++;
                String htmlSectionImage = "";
                String htmlSection = "";

                String scDynamic = cms.contentshow(sectionContent, "DynamicContent");
                String scTitle = cms.contentshow(sectionContent, "Title").replaceAll(" & ", " &amp; ");
                String scText = cms.contentshow(sectionContent, "Text");
                String scMoreLink = cms.contentshow(sectionContent, "MoreLink");
                if (CmsAgent.elementExists(scMoreLink)) {
                    // Escape the URI, if necessary
                    if (scMoreLink.contains("?")) {
                        scMoreLink = StringEscapeUtils.escapeHtml(scMoreLink);
                    }
                }
                String scMoreLinkText = cms.contentshow(sectionContent, "MoreLinkText");
                String scCssClass = cms.contentshow(sectionContent, "CssClass");

                I_CmsXmlContentContainer scImage = cms.contentloop(sectionContent, "Image");
                while (scImage.hasMoreContent()) {
                    String scImageUri = cms.contentshow(scImage, "URI");
                    String scImageAlt = cms.contentshow(scImage, "Title");
                    String scImageText = cms.contentshow(scImage, "Text").replaceAll(" & ", " &amp; ");
                    String scImageSource = cms.contentshow(scImage, "Source");
                    String scImageSize = cms.contentshow(scImage, "Size");
                    String scImageFloat = cms.contentshow(scImage, "Float");
                    String scImageType = cms.labelUnicode("label.np." + cms.contentshow(scImage, "ImageType").toLowerCase());
                    
                    // Modify alt text
                    if (scImageAlt != null && (scImageAlt.equalsIgnoreCase("none") || scImageAlt.equals("-")))
                        scImageAlt = "";

                    String imageTagPrimaryAttribs = " src=\"" + cms.link(scImageUri) + "\"";
                    String imageTagSecondaryAttribs = " alt=\"" + scImageAlt + "\"";
                    // Scale image, if needed
                    imageHandle = new CmsImageScaler(cmso, cmso.readResource(scImageUri));
                    int imageMaxWidth = sectionColspan == 4 ? IMAGE_SIZE_M : IMAGE_SIZE_L;
                    if (imageHandle.getWidth() > imageMaxWidth) { // Image larger than defined size, needs downscale
                        targetScaler.setWidth(imageMaxWidth);
                        //targetScaler.setHeight(new CmsImageProcessor().getNewHeight(imageMaxWidth, imageHandle.getWidth(), imageHandle.getHeight()));
                        CmsImageScaler downScaler = imageHandle.getReScaler(targetScaler);
                        imageTagPrimaryAttribs = cms.img(scImageUri, downScaler, null, true);
                    }
                    /*
                    htmlSectionImage += "\n" + (CmsAgent.elementExists(scMoreLink) ? "<a href=\"" + cms.link(scMoreLink) + "\">" : "") 
                                                + "<img " + imageTagPrimaryAttribs + imageTagSecondaryAttribs + " />"
                                            + (CmsAgent.elementExists(scMoreLink) ? "</a>" : "");
                    if (CmsAgent.elementExists(scImageText) || CmsAgent.elementExists(scImageSource)) {
                        htmlSectionImage += "\n<span class=\"imagetext\">";
                        if (CmsAgent.elementExists(scImageText))
                            htmlSectionImage += CmsAgent.stripParagraph(scImageText);
                        if (CmsAgent.elementExists(scImageSource))
                            htmlSectionImage += "<span class=\"imagecredit\"> " + scImageType + ": " + scImageSource + "</span>";
                        htmlSectionImage += "</span>";
                    }
                    htmlSectionImage += "\n</span>";
                    */
                    htmlSectionImage = "<img " + imageTagPrimaryAttribs + imageTagSecondaryAttribs + " />";
                }


                //out.print("<div class=\"" + widthClasses[sectionColspan] + " featured-box");
                //out.print("<div class=\"span1 featured-box");
                //out.print("<div class=\"span1 " + (overlayHeadings ? "featured" : "portal") + "-box");
                //out.print("<div class=\"span1 " + (htmlSectionImage.isEmpty() ? "portal" : "featured") + "-box"); // Switch on image existence instead of "overlay headings"
                out.print("<div class=\"layout-box " + (htmlSectionImage.isEmpty() ? "portal" : "featured") + "-box" + (textAsHoverBox ? " hb-text" : "")); // Switch on image existence instead of "overlay headings"
                /*
                if ((scCount+sectionColspan) % sectionColspan ==1)
                    out.print(" pull-left");
                else if (scCount % sectionColspan == 0)
                    out.print(" pull-right");
                */
                if (CmsAgent.elementExists(scCssClass)) {
                    out.print(" " + scCssClass);
                    //if (!scCssClass.startsWith("span")) {
                        //out.print(" span1");
                    //}
                }
                //else {
                    //out.print(" span1");
                //}
                out.println("\">");

                String link = CmsAgent.elementExists(scMoreLink) ? "<a" 
                                                                    + (overlayHeadings ? " class=\"featured-link\"" : "") 
                                                                    + " href=\"" + cms.link(scMoreLink) + "\""
                                                                    + (CmsAgent.elementExists(scText) 
                                                                        && textAsHoverBox
                                                                            ? " data-hoverbox=\"" + org.apache.commons.lang.StringEscapeUtils.escapeHtml(scText) + "\"" 
                                                                            : "")
                                                                    /*+ (overlayHeadings 
                                                                        && !htmlSectionImage.isEmpty() 
                                                                        && CmsAgent.elementExists(scText)                                                                
                                                                            ? " data-hoverbox=\"" + org.apache.commons.lang.StringEscapeUtils.escapeHtml(scText) + "\"" 
                                                                            : "")*/
                                                                    + ">"
                                                                    //+ "<div class=\"card\">" 
                                                               : "";
                /*
                out.println(CmsAgent.elementExists(scMoreLink) ? "<a" 
                                                                    + (overlayHeadings ? " class=\"featured-link\"" : "") 
                                                                    + " href=\"" + cms.link(scMoreLink) + "\">"
                                                                    //+ "<div class=\"card\">" 
                                                               : "");
                */
                if (boxed && !link.isEmpty())
                    out.println(link);
                if (!htmlSectionImage.isEmpty())
                    out.println("<div class=\"card\">");
                if (!boxed && !link.isEmpty())
                    out.println(link);
                if (overlayHeadings)
                    out.println("<div class=\"autonomous\">");
                // <div class="fourcol-equal single left"> OR <div class="fourcol-equal single" id="rightside">
                if (CmsAgent.elementExists(scTitle)) {
                    /*
                    if (!CmsAgent.elementExists(sectionHeading)) {
                        //out.print("<h3 class=\"portal-box-heading" + (overlayHeadings ? " overlay" : " bluebar-dark") + "\">");
                        out.print("<h2 class=\"portal-box-heading" + (overlayHeadings ? " overlay" : " bluebar-dark") + "\">");
                    } else {
                        out.print("<h3 style=\"color:#777; font-size:1.6em; border-bottom:1px solid #999; margin-top:0.2em; text-shadow: 1px 1px 2px #ddd;\">");
                    }
                    */
                    out.print("<h2 class=\"portal-box-heading" + (overlayHeadings ? " overlay" : " bluebar-dark") + "\">");
                    out.println("<span>");
                    out.print(scTitle);
                    /*
                    if (CmsAgent.elementExists(scMoreLink) && CmsAgent.elementExists(scMoreLinkText)) {
                        //out.println(" <span class=\"heading-more\"><a href=\"" + cms.link(scMoreLink) + "\">" + scMoreLinkText +"</a></span>");
                        out.println(" <span class=\"heading-more\">" + scMoreLinkText +"</span>");
                    }
                    */
                    //out.println("</h3>");
                    out.println("</span>");
                    out.println("</h2>");
                }
                if (!htmlSectionImage.isEmpty()) {
                    out.println(htmlSectionImage);
                }
                if (overlayHeadings)
                    out.println("</div>");

                if (!boxed && CmsAgent.elementExists(scMoreLink))
                    out.println("</a>");

                out.println("<div class=\"box-text\">");

                //if (CmsAgent.elementExists(scText))
                //if (CmsAgent.elementExists(scText) && !(overlayHeadings && !htmlSectionImage.isEmpty()))
                if (CmsAgent.elementExists(scText) && !textAsHoverBox)
                    out.println(scText);

                if (CmsAgent.elementExists(scDynamic)) {
                    scDynamic += (scDynamic.contains("?") ? "&" : "?") + "dynamic_container=portal_page_section";
                    // Request to suppress the list's own heading
                    scDynamic += "&override_heading=none";
                    String scDynamicPath = scDynamic.split("\\?")[0];
                    String scDynamicParams = scDynamic.split("\\?")[1];
                    try {
                        cms.includeAny(scDynamicPath, null, CmsRequestUtil.createParameterMap(scDynamicParams));
                    } catch (Exception ee) {
                        out.println("<!-- Portal page failed to include dynamic section content '" + scDynamic + "' with includeAny(), error was: " + ee.getMessage() + " -->");
                        cms.include(scDynamicPath, null, CmsRequestUtil.createParameterMap(scDynamicParams));
                    }
                    /*
                    if (scDynamic.contains("?")) {
                        try {
                            
                            cms.include(scDynamicPath, null, CmsRequestUtil.createParameterMap(scDynamicQuery));
                        } catch (Exception e) {
                            out.println("<!-- Error including dynamic content: " + e.getMessage() + " -->");
                        }
                    } else {
                        cms.includeAny(scDynamic, "resourceUri");
                    }
                    //*/
                }

                //if (!boxed && CmsAgent.elementExists(scMoreLink))
                if (!boxed && !textAsHoverBox && CmsAgent.elementExists(scMoreLink))
                    out.println("<p><a class=\"cta more\" href=\"" + cms.link(scMoreLink) + "\">" + (CmsAgent.elementExists(scMoreLinkText) ? scMoreLinkText : "Read more") + "</a></p>");

                out.println("</div><!-- .box-text -->");

                if (!htmlSectionImage.isEmpty())
                    out.println("</div><!-- .card -->");

                if (boxed && CmsAgent.elementExists(scMoreLink))
                    out.println("</a>");
                //out.println(CmsAgent.elementExists(scMoreLink) ? "</div></a>" : "");

                out.println("</div><!-- .portal-box / .featured-box -->");
            }
        }
        if (!isDynamicContentSection) {
            // End the "boxes" wrapper
            out.println("</div>");
        }
        // End the section wrapper
        out.println("</section><!-- .layout-group -->");
    }
    
    // End the section wrapper
    //out.println("</div><!-- .column.portal.right -->");
    //out.println("</article><!-- .main-content.portal -->");
    /*if (shareLinks) {
        out.println(cms.getContent(SHARE_LINKS));
        sess.setAttribute("share", "true");
    }*/

} // While container.hasMoreContent()


//
// Include lower part of main template
//
cms.include(template, elements[1], EDITABLE_TEMPLATE);
%>