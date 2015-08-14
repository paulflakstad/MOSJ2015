<%-- 
    Document   : paragraphhandler.jsp - Common paragraph template
    Dependency : no.npolar.common.gallery, no.npolar.util
    Created on : 03.jun.2010, 20:58:57
    Updated on : 20.sep.2011, 14:49:00
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.*,
                 no.npolar.util.contentnotation.*,
                 java.util.*,
                 java.util.regex.*,
                 java.io.IOException,
                 java.io.PrintWriter,
                 org.apache.commons.lang.StringEscapeUtils,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.loader.CmsImageScaler" session="true" %><%!
/**
* Wraps an image in a container, possibly also with image text and source.
*/
public String getImageContainer(CmsAgent cms, 
                                String imageTag,
                                int imageWidth, 
                                int imagePadding,
                                String imageText, 
                                String imageSource, 
                                String imageType, 
                                String imageSize, 
                                String imageFloat) {
    
    final String IMAGE_CONTAINER = "span";
    final String TEXT_CONTAINER = "span";
    // CSS class strings to append to the HTML, defined by the given image size
    final Map<String, String> sizeClasses = new HashMap<String, String>();
    sizeClasses.put("S", " thumb");
    sizeClasses.put("M", "");
    sizeClasses.put("L", " big");
    sizeClasses.put("XL", "");
    
    String imageFrameHTML =
            "<" + IMAGE_CONTAINER + " class=\"media" // The base class
             + ("left".equalsIgnoreCase(imageFloat) || "right".equalsIgnoreCase(imageFloat) ? " pull-".concat(imageFloat.toLowerCase()) : "") // Add " pull-left" / " pull-right" if necessary
             + sizeClasses.get(imageSize) // Add " thumb" / " big" if necessary
             + "\">"
             + imageTag;

    if (cms.elementExists(imageText) || cms.elementExists(imageSource)) {
        imageFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"caption highslide-caption\">" +
                    (cms.elementExists(imageText) ? cms.stripParagraph(imageText) : "") + 
                    (cms.elementExists(imageSource) ? ("<span class=\"credit\"> " + imageType + ": " + imageSource + "</span>") : "") +
                "</" + TEXT_CONTAINER + ">";
    }
    imageFrameHTML += "</" + IMAGE_CONTAINER + ">";
    return imageFrameHTML;
}

/**
* Wraps a video in a container, possibly also with caption and credit.
*/
public void printVideoContainer(CmsAgent cms, String videoUri,
                                int videoWidth, int videoPadding,
                                String caption, String credit, String videoFloatChoice,
                                JspWriter outWriter) 
                throws CmsException, JspException, IOException {
    final String VIDEO_CONTAINER = "span";
    final String TEXT_CONTAINER = "span";
    String videoFrameHTML =
             "<span class=\"media" 
             + ("left".equalsIgnoreCase(videoFloatChoice) || "right".equalsIgnoreCase(videoFloatChoice) ? " pull-".concat(videoFloatChoice.toLowerCase()) : "")
             + "\">";
    // Print the first part
    outWriter.print(videoFrameHTML);
    // Then let the video handler print the video
    Map params = new HashMap();
    params.put("resourceUri", videoUri);
    params.put("width", videoWidth);
    // Allow overriding of caption and credit
    if (caption != null & !caption.isEmpty())
        params.put("caption", caption);
    if (credit != null & !credit.isEmpty())
        params.put("credit", credit);
    String videoTemplate = cms.getCmsObject().readPropertyObject(videoUri, "template-elements", false).getValue("Undefined template-elements");
    cms.include(videoTemplate, null, params);

    // Reset HTML
    videoFrameHTML = ""; 
    /*if (cms.elementExists(caption) || cms.elementExists(credit)) {
        videoFrameHTML += 
                "<" + TEXT_CONTAINER + " class=\"imagetext highslide-caption\">" +
                    (cms.elementExists(caption) ? cms.stripParagraph(caption) : "") + 
                    (cms.elementExists(credit) ? ("<span class=\"imagecredit\"> Video: " + credit + "</span>") : "") +
                "</" + TEXT_CONTAINER + ">";
    }*/
    videoFrameHTML += "</span>";
    outWriter.print(videoFrameHTML);
}

/**
* Gets an exception's stack trace as a string.
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

public Map<String, String> getParameters(String uri) {
    String paramStr = null;
    try {
        paramStr = uri.split("\\?")[1];
    } catch (Exception e) {
        return new HashMap<String, String>();
    }
    Map<String, String> params = new HashMap<String, String>();
    try {
        String[] keyVal = paramStr.split("\\&");
        for (int i = 0; i < keyVal.length; i++) {
            try {
                params.put(keyVal[i].split("=")[0], keyVal[i].split("=")[1]);
            } catch (ArrayIndexOutOfBoundsException oob) {
                params.put(keyVal[i], "on");
            }
        }
    } catch (Exception e) {
        // why ???
    }
    return params;
}
%><%
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();

ContentNotationResolver cnr = null;
try {
    cnr = (ContentNotationResolver)session.getAttribute(ContentNotationResolver.SESS_ATTR_NAME);
} catch (Exception e) {
    out.println("\n<!-- Content notation resolver should be initialized in master template. Initializing one now to prevent crash ... -->");
    cnr = new ContentNotationResolver();
    session.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
}

// CmsImageProcessor is just a CmsImageScaler class, with some additional helper methods
CmsImageProcessor imgPro            = new CmsImageProcessor();
// 4 = "Scale to exact target size". For other image scaler types, see http://www.opencms.org/javadoc/core/org/opencms/loader/CmsImageScaler.html#getType()
imgPro.setType(4); 
// The image saving quality, in percent
imgPro.setQuality(100);

String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

int galleryCounter                  = 0;

// IMPORTANT: Embedded gallery version requires the gallery module installed!!!
final String GALLERY_HANDLER        = "/system/modules/no.npolar.common.gallery/elements/gallery-standalone.jsp";

final boolean EDITABLE              = false;
// boolean EDITABLE_TEMPLATE     = false; // Don't want this here, it's in the template already (i.e. "ivorypage.jsp" or "newsbulletin.jsp")
final int IMAGE_PADDING             = 4;//0; // The padding for the image. Needed to generate the width attribute for image containers.

// Image widths - one for floated images, one for full-width images
// (Assume images are CSS-scaled, but use these dimensions to make the image files as small as possible)
final int IMAGE_WIDTH_FLOAT = 450;//380;
final int IMAGE_WIDTH_FULL = 940;

// Image variables
String imagePath                    = null; // The image path
String imageTag                     = null; // The <img> tag
String imageSource                  = null; // The image's source or copyright proprietor
String imageCaption                 = null; // The image caption
String imageTitle                   = null; // The image title (the alt text)
int    imageRescaleWidth            = -1;   // The width (in pixels) to rescale image to
String imageFloatChoice             = null; // Left, right, none
String imageTypeChoice              = null; // Photo, graphics, etc.
String imageSizeChoice              = null; // S, M, L (M is default)

List<String> imagesBefore = new ArrayList<String>();
List<String> imagesFullWidthBefore = new ArrayList<String>();
List<String> imagesFullWidthAfter = new ArrayList<String>();

 // XML content containers
I_CmsXmlContentContainer container = null; 
I_CmsXmlContentContainer paragraphs = null;
I_CmsXmlContentContainer textBoxContainer = null;
I_CmsXmlContentContainer imageContainer = null;
I_CmsXmlContentContainer videoContainer = null;

// String variables for structured content elements
String title = null;
String text = null;

// Wrapper class
String wrapperClass = null;
boolean accordion = false;
boolean accordionCollapsed = false;

final String DEFAULT_ELEMENT_NAME_PARAGRAPH = "Paragraph";
String paragraphElementName = DEFAULT_ELEMENT_NAME_PARAGRAPH;

if (request.getAttribute("paragraphContainer") != null) {
    container = (I_CmsXmlContentContainer)request.getAttribute("paragraphContainer");
    if (request.getAttribute("paragraphElementName") != null) 
        paragraphElementName = (String)request.getAttribute("paragraphElementName");
}
else if (request.getAttribute("paragraphElementName") != null) {
    paragraphElementName = (String)request.getAttribute("paragraphElementName");
}
if (container == null) {
//else {
    // Load the content
    container = cms.contentload("singleFile", "%(opencms.uri)", EDITABLE);
}

//out.println("<!-- PARAGRAPH_HANDLER: paragraphElementName was '" + paragraphElementName + "', paragraphContainer was '" + container + "' -->");
//out.println("<!-- PARAGRAPH_HANDLER: entering container... -->");
// Process the content
while (container.hasMoreContent()) {
    //out.println("<!-- PARAGRAPH_HANDLER: inside container... -->");
    // We will only be processing the "Paragraph" element
    paragraphs = cms.contentloop(container, paragraphElementName);
    // Process content (paragraphs)
    while (paragraphs.hasMoreContent()) {
        // Clear the image lists
        imagesBefore.clear();
        imagesFullWidthAfter.clear();
        imagesFullWidthBefore.clear();
        
        // Accordion?
        if (CmsAgent.elementExists(cms.contentshow(paragraphs, "WrapperClass"))) {
            wrapperClass = cms.contentshow(paragraphs, "WrapperClass");
        } else {
            wrapperClass = null;
            //wrapperClass = "";
        }
        
        try { accordion = wrapperClass.contains("toggleable") ? true : false; } catch (Exception e) {}
        try { accordionCollapsed = accordion && wrapperClass.contains("collapsed") ? true : false; } catch (Exception e) {}
        
        //out.println("<div class=\"paragraph\">");
        %>
        <section class="paragraph clearfix">
        <%
        if (wrapperClass != null) {
            %> 
            <div class="<%= wrapperClass %>">
            <%
        }
        // Get the paragraph title and text
        title   = request.getAttribute("paragraphTitle") == null ? cms.contentshow(paragraphs, "Title").replaceAll(" & ", " &amp; ") : request.getAttribute("paragraphTitle").toString();
        text    = cms.contentshow(paragraphs, "Text");

        // Print the paragraph title
        if (CmsAgent.elementExists(title)) {
            if (accordion) {
                %> 
                <a class="toggletrigger" href="javascript:void(0);">
                <%
            } else {
            %>
                <h2>
            <%
            }
            try {
                out.print(cnr.resolve(title));
            } catch (Exception e) {
                out.print("<!--\nERROR trying to resolve content notation for the title '" + title + "'\n-->");
                out.print(title);
            }
            if (!accordion) {
                %> 
                </h2>
                <%
            } else {
                %>
                </a><div class="toggletarget">
                <%
            }
        }


        //
        // Images
        //
        try {
            imageContainer = cms.contentloop(paragraphs, "Image");
            while (imageContainer.hasMoreContent()) {
                imagePath       = cms.contentshow(imageContainer, "URI");
                imageCaption    = cms.contentshow(imageContainer, "Text");
                imageTitle      = cms.contentshow(imageContainer, "Title");
                imageSource     = cms.contentshow(imageContainer, "Source");
                imageTypeChoice = cms.labelUnicode("label.pageelements." + cms.contentshow(imageContainer, "ImageType").toLowerCase());
                imageSizeChoice = cms.contentshow(imageContainer, "Size");
                if (!CmsAgent.elementExists(imageSizeChoice))
                    imageSizeChoice = "M"; // Default
                imageFloatChoice= cms.contentshow(imageContainer, "Float");
                imageRescaleWidth = "right".equalsIgnoreCase(imageFloatChoice) || "left".equalsIgnoreCase(imageFloatChoice) ? IMAGE_WIDTH_FLOAT : IMAGE_WIDTH_FULL;

                int imageHeight = -1;
                int imageWidth  = imageRescaleWidth;//IMG_WIDTH_M;
                boolean scaled  = false;
                
                String imageSrc = "";

                // Check to make sure that the image exists
                //if (cmso.existsResource(imagePath)) {
                if (cmso.existsResource(imagePath.substring(0, imagePath.indexOf("?") == -1 ? imagePath.length() : imagePath.indexOf("?")))) {
                    int[] imageDimensions = cms.getImageSize(cmso.readResource(imagePath));
                    // DOWNSCALE only!
                    if (imageDimensions[0] > imageRescaleWidth) {
                        // Downscale needed
                        imageHeight = CmsAgent.calculateNewImageHeight(imageRescaleWidth, imageDimensions[0], imageDimensions[1]);

                        imgPro.setWidth(imageRescaleWidth);
                        imgPro.setHeight(imageHeight);

                        // Get the "src" attribute from the downscaled image's <img> tag
                        imageSrc = (String)CmsAgent.getTagAttributesAsMap(cms.img(imagePath, imgPro.getReScaler(imgPro), null)).get("src");
                        scaled = true;
                    }
                    else {
                        // No downscale needed
                        imageSrc = cms.link(imagePath);
                        imageWidth = imageDimensions[0];
                    }
                    // ALWAYS wrap the scaled image in a link to the original image (even if no downscale was applied)
                    imageTag = "<img src=\"" + imageSrc + "\""
                                    + " alt=\"" + (CmsAgent.elementExists(imageTitle) ? imageTitle : "") + "\""
                                    + (scaled ? "" : " style=\"width:" + imageWidth + "px;\"")
                                    + " />";
                    // BEGIN NEW
                    imageTag = ImageUtil.getImage(cms, imagePath, (CmsAgent.elementExists(imageTitle) ? imageTitle : null));
                    
                    String hsLinkedImageUri = ImageUtil.getWidthConstrainedUri(cms, imagePath); // NOTE: Will be ready linked with cms.link(...)
                    
                    imageTag = "<a href=\"" + hsLinkedImageUri + "\"" 
                    // END NEW
                    //imageTag = "<a href=\"" + cms.link(imagePath) + "\"" 
                                    + " title=\"" + cms.labelUnicode("label.pageelements.largerimage") + "\""
                                    + " class=\"highslide\""
                                    + " onclick=\"return hs.expand(this);\">"
                                        + imageTag
                                    + "</a>";
                    imageTag += "<!-- original image width was " + ImageUtil.getWidth(cmso, imagePath) + " -->";
                }
                else {
                    imageTag = "<img src=\"\" alt=\"\" />";
                    throw new ServletException("The referred image '" + (imagePath == null ? "null" : imagePath) + "' does not exist.");
                }
                // Get the image container
                String imageHtml = getImageContainer(cms, imageTag, imageWidth, IMAGE_PADDING, imageCaption, imageSource, imageTypeChoice, imageSizeChoice, imageFloatChoice);
                if ("after".equalsIgnoreCase(imageFloatChoice))
                    imagesFullWidthAfter.add(imageHtml);
                else {
                    if ("none".equalsIgnoreCase(imageFloatChoice))
                        imagesFullWidthBefore.add(imageHtml);
                    else
                        imagesBefore.add(imageHtml);
                    
                }
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while reading image information.");
        }


        //
        // Videos
        //
        try {
            //out.println("\n<!-- Entering video section -->");
            String videoPath = null;
            String videoCaption = null;
            String videoCredit = null;
            String videoSizeChoice = null;
            String videoFloatChoice = null;
            
            videoContainer = cms.contentloop(paragraphs, "Video");
            /*
            if (!videoContainer.getCollectorResult().isEmpty())
                out.println("<!-- Videos in this paragraph: " + videoContainer.getCollectorResult().size() + " -->");
            else
                out.println("<!-- No videos in this paragraph -->");
            */
            while (videoContainer.hasMoreContent()) {
                videoPath       = cms.contentshow(videoContainer, "URI");
                videoCaption    = cms.contentshow(videoContainer, "Caption");
                videoCredit     = cms.contentshow(videoContainer, "Credit");
                videoSizeChoice = cms.contentshow(videoContainer, "Size");
                videoFloatChoice= cms.contentshow(videoContainer, "Float");
                
                //int videoWidth   = IMAGE_PX_SIZES.get(IMAGE_SIZES.indexOf(videoSizeChoice)).intValue();
                int videoWidth = -1;
                
                // Check to make sure that the video exists
                if (!cmso.existsResource(videoPath)) {
                    throw new ServletException("A video was added to a paragraph, but the video does not exist. (Path was '" +
                            (videoPath == null ? "null" : videoPath) + "').");
                }
                
                try {
                    videoCaption = cnr.resolve(videoCaption);
                } catch (Exception e) {
                    out.println("\n<!--\nCould not resolve hoverbox entitites:\n" + e.getMessage() + "\n-->");
                }
                
                // Output the video container
                //printVideoContainer(cms, videoPath, videoWidth+(2*IMAGE_PADDING), 0, videoCaption, videoCredit, videoFloatChoice, out);
                printVideoContainer(cms, videoPath, -1, 0, videoCaption, videoCredit, videoFloatChoice, out);
                
            }
            
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while printing video.");
        }
        
        
        
        
        //
        // Images before the paragraph text
        //
        Iterator<String> i = imagesFullWidthBefore.iterator();
        String imageHtml = null;
        while (i.hasNext()) {
            imageHtml = i.next();
            try {
                imageHtml = cnr.resolve(imageHtml);
            } catch (Exception e) {
                out.println("\n<!--\nCould not resolve hoverbox entitites:\n" + e.getMessage() + "\n-->");
            }
            out.println(imageHtml);
        }
        i = imagesBefore.iterator();
        while (i.hasNext()) {
            imageHtml = i.next();
            try {
                imageHtml = cnr.resolve(imageHtml);
            } catch (Exception e) {
                out.println("\n<!--\nCould not resolve hoverbox entitites:\n" + e.getMessage() + "\n-->");
            }
            out.println(imageHtml);
        }
        
        //
        // Text box
        //
        try {
            String tbTitle, tbText, tbUri;
            // Print out the text box
            textBoxContainer = cms.contentloop(paragraphs, "TextBox");
            while (textBoxContainer.hasMoreContent()) {
                tbTitle = cms.contentshow(textBoxContainer, "Title");
                tbText  = cms.contentshow(textBoxContainer, "Text");
                tbUri   = cms.contentshow(textBoxContainer, "URI");
                
                // Handle case: tbUri set (fetch stuff from that file)
                String textFromUri = "";
                if (CmsAgent.elementExists(tbUri)) {
                    String titleFromUri = cms.property("Title", tbUri, ""); // Read title from external file (if any)
                    if (!titleFromUri.isEmpty() && !CmsAgent.elementExists(tbTitle)) // If no title was set for this text box, and an external file did exist ...
                        tbTitle = titleFromUri; // ... use the external page's title as the text box title
                
                    I_CmsXmlContentContainer tbFile = cms.contentload("singleFile", tbUri, false);
                    out.println("<!-- loaded '" + tbUri + "' ... -->");
                    while (tbFile.hasMoreContent()) {
                        String tbFileIngress = cms.contentshow(tbFile, "Intro");
                        if (CmsAgent.elementExists(tbFileIngress))
                            textFromUri += tbFileIngress;
                        else
                            out.println("<!-- No page summary found on '" + tbUri + "' -->");
                        I_CmsXmlContentContainer tbFileParagraph = cms.contentloop(tbFile, "Paragraph");
                        
                        int tbFileParagraphsIncluded = 0;
                        while (tbFileParagraph.hasMoreContent()) {
                            if (tbFileParagraphsIncluded++ == 0) {
                                String tbFileParagraphTitle = cms.contentshow(tbFileParagraph, "Title");
                                String tbFileParagraphText = cms.contentshow(tbFileParagraph, "Text");
                                if (CmsAgent.elementExists(tbFileParagraphTitle))
                                    textFromUri += "<p><strong>" + tbFileParagraphTitle + "</strong></p>";
                                if (CmsAgent.elementExists(tbFileParagraphText))
                                    textFromUri += tbFileParagraphText;
                            } else {
                                // 2nd paragraph found: Don't print this here, provide a "Read more" link instead
                                textFromUri += "<p><a href=\"" + cms.link(tbUri) + "\">" + (loc.equalsIgnoreCase("no") ? "Les mer" : "Read more") + "&nbsp;&hellip;</a></p>";
                                break; // Then break out of the paragraphs loop
                            }
                        }
                    }
                }
                
                out.println("<aside class=\"textbox pull-right\">");
                if (cms.elementExists(tbTitle)) {
                    out.println("<h5>" + tbTitle + "</h5>");
                }
                if (!textFromUri.isEmpty())
                    tbText = textFromUri + tbText;
                if (cms.elementExists(tbText)) {
                    try {
                        tbText = cnr.resolve(tbText);
                    } catch (Exception e) {
                        out.println("\n<!--\nCould not resolve hoverbox entitites:\n" + e.getMessage() + "\n-->");
                    }
                    out.println("<div class=\"textbox-content\">" + tbText + "</div>");
                    if (tbText.length() > 200) {
                        out.println("<script type=\"text/javascript\">");
                        out.println("// Vertical accordion here");
                        out.println("</script>");
                    }
                }
                out.println("</aside><!-- .textbox -->");
            }
        }
        catch (NullPointerException npe1) {
            throw new ServletException("Null pointer encountered while creating text box.");
        }
        
        //
        // Paragraph text
        //
        if (cms.elementExists(text)) {
            try {
                text = cnr.resolve(text);
            } catch (Exception e) {
                out.println("\n<!--\nCould not resolve hoverbox entitites:\n" + e.getMessage() + "\n-->");
            }
            out.println(CmsAgent.obfuscateEmailAddr(text, true));
        }
        
        //
        // Images after the paragraph text
        //
        i = imagesFullWidthAfter.iterator();
        while (i.hasNext()) {
            out.println(i.next());
        }
        
        
        
        
        //
        // Extension
        //
        boolean wrapExtensionInside = false;
        String extFile = null;
        String extFilePath = null;
        Map extParams = new HashMap();
        boolean extensionIsJsp = false;
        //boolean extensionParameters = false;
        try {
            extFile = cms.contentshow(paragraphs, "Extension");
            if (CmsAgent.elementExists(extFile)) {
                //out.println("<!-- Extension present: " + extFile + " -->");
                extFilePath = extFile.split("\\?")[0];
                extensionIsJsp = cmso.readResource(extFilePath).getTypeId() == OpenCms.getResourceManager().getResourceType("jsp").getTypeId();
                // Get URL parameters from the extension (e.g. when extension URI is "/my/extension.jsp?folder=/my/folder/&heading=h3")
                extParams = getParameters(extFile);
                if (!extParams.isEmpty()) {
                    try {
                        if (extParams.get("__wrap").equals("true")) { //(extFile.split("\\?")[1].equals("wrapinside")) {
                            wrapExtensionInside = true;
                            extParams.remove("__wrap");
                        } 
                        
                        /*
                        if (extParams.get("folder") != null) {
                            extParams.put("folder", getParameters(extFile).get("folder"));
                            //out.println("<!-- Determined extension folder: " + getParameters(extFile).get("folder") + " -->");
                        }
                        //*/
                        //out.println("<!-- 'wrapExtensionInside' is " + wrapExtensionInside + ", getParameters(extFile).get(\"__wrap\")='" + getParameters(extFile).get("__wrap") + "' -->");
                    } catch (Exception e) {
                        // Ignore, this should indicate that no wrapping parameter is present, so do the default thing.
                    }
                }
                // Extension (if WRAPPED inside paragraph)
                if (CmsAgent.elementExists(extFilePath) && wrapExtensionInside) {
                    //out.println("<!-- Extension is '" + extFilePath + "' -->");
                    //if (extFilePath.endsWith(".jsp")) {
                    if (extensionIsJsp) {
                        cms.include(extFilePath, null, extParams);
                    } else {
                        cms.includeAny(extFilePath, "resourceUri");
                    }
                } else {
                    //out.println("<!-- Extension is '" + extFilePath + "', valid extension = " + CmsAgent.elementExists(extFilePath) + " -->");
                }
            } else {
                //out.println("<!-- No extension present -->");
            }
        } catch (Exception e3) {
            out.println("<!-- Oh noes, the extension crashed it! Message was: " + e3.getMessage() + " -->");
        }
        /* // Backup of extension before modification (which was done when upgrading SEAPOP)
        boolean wrapExtensionInside = false;
        String extFile = null;
        String extFilePath = null;
        try {
            extFile = cms.contentshow(paragraphs, "Extension");
            extFilePath = extFile.split("\\?")[0];
            try {
                if (getParameters(extFile).get("__wrap").equals("true")) { //(extFile.split("\\?")[1].equals("wrapinside")) {
                    wrapExtensionInside = true;
                } 
                //out.println("<!-- 'wrapExtensionInside' is " + wrapExtensionInside + ", getParameters(extFile).get(\"__wrap\")='" + getParameters(extFile).get("__wrap") + "' -->");
            } catch (Exception e) {
                // Ignore, this should indicate that no wrapping parameter is present, so do the default thing.
            }
            // Extension (if WRAPPED inside paragraph)
            if (CmsAgent.elementExists(extFilePath) && wrapExtensionInside) {
                //out.println("<!-- Extension is '" + extFilePath + "' -->");
                cms.includeAny(extFilePath, "resourceUri");
            } else {
                //out.println("<!-- Extension is '" + extFilePath + "', valid extension = " + CmsAgent.elementExists(extFilePath) + " -->");
            } 
        } catch (Exception e3) {
            out.println("<!-- Oh noes, the extension crashed it! Message was: " + e3.getMessage() + " -->");
        }
        */
        
        
        //
        // Embedded gallery
        //
        try {
            I_CmsXmlContentContainer embeddedGalleries = cms.contentloop(paragraphs, "EmbeddedGallery");
            while (embeddedGalleries.hasMoreContent()) {
                String galleryUri = cms.contentshow(embeddedGalleries);
                if (CmsAgent.elementExists(galleryUri)) {
                    request.setAttribute("resourceUri", galleryUri); // Set the path to the gallery
                    request.setAttribute("galleryIndex", Integer.valueOf(++galleryCounter)); // Set the gallery counter (one page may contain multiple galleries)
                    request.setAttribute("thumbnailSize", Integer.valueOf(100)); // Set thumbnail size (override the value in the gallery file)
                    request.setAttribute("headingType", "h3"); // Set the heading type
                    cms.include(GALLERY_HANDLER);
                }
            }
        }
        catch (NullPointerException npe2) {
            throw new ServletException("NullPointer encountered while reading path to embedded gallery.");
        }
        
        
        //out.println("</div><!-- .paragraph -->");
        if (accordion) {
            %> 
                </div><!-- .toggletarget -->
            <%
        }
        if (wrapperClass != null) {
            %> 
            </div><!-- wrapper class --> 
            <%
        }
        %>
        </section><!-- .paragraph -->
        <%
        
        //
        // Extension (if NOT WRAPPED inside paragraph)
        //
        try {
            if (CmsAgent.elementExists(extFilePath) && !wrapExtensionInside) {
                //cms.includeAny(extFilePath, "resourceUri");
                if (extensionIsJsp) {
                    cms.include(extFilePath, null, extParams);
                } else {
                    cms.includeAny(extFilePath, "resourceUri");
                }
            } else {
                //out.println("<!-- Extension is '" + extFilePath + "', valid extension = " + CmsAgent.elementExists(extFilePath) + " -->");
            } 
            /*String extFile = cms.contentshow(paragraphs, "Extension");
            // Extension
            if (CmsAgent.elementExists(extFile)) {
                //out.println("<!-- Paragraph extension: '" + extFile + "' -->");
                cms.includeAny(extFile, "resourceUri");
            } */          
        } catch (Exception e3) {
            out.println("<!-- Oh noes, the extension crashed it! Message was: " + e3.getMessage() + " -->");
        }
    }
    
}

session.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
//out.println("<!-- PARAGRAPH_HANDLER: done with container. -->");
%>