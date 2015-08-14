<%@page session="false" 
        isErrorPage="true" 
        contentType="text/html" 
        import="org.opencms.jsp.*, org.opencms.jsp.util.*, java.util.*, no.npolar.util.*" 
%><%
CmsJspStatusBean cms = new CmsJspStatusBean(pageContext, request, response, exception);

// Get the requested page's URI (the one that caused the error)
String requestedPageUri = ""; 
try { 
    requestedPageUri = (String)request.getAttribute("javax.servlet.error.request_uri");
} catch (Exception e) {
}

// Determine locale
Locale preferredLocale = new Locale("en"); // Default
if (requestedPageUri.startsWith("/opencms/opencms/no/")) {
    preferredLocale = new Locale("no");
}

// Template
String template = "/system/modules/no.npolar.mosj/templates/mosj.jsp";
// Image
//String imgUri = (cms.getStatusCode() == 500 ? "/" : "/sites/mosj/") + preferredLocale.toString() + "/img/" + cms.getStatusCode() + ".jpg";
String imgUri = "/sites/mosj/" + preferredLocale.toString() + "/img/" + cms.getStatusCode() + ".jpg";
imgUri = cms.getRequestContext().removeSiteRoot(imgUri);
// Content folder
String contentFolderUri = "/system/handler/";
// Content page
String contentFileUri = contentFolderUri + "content" + cms.getStatusCode() + ".html";
// Content page title
String contentTitle = cms.getContent(contentFileUri, "PageTitle", preferredLocale);
// Content (the "Intro" field holds everything)
String content = cms.getContent(contentFileUri, "Intro", preferredLocale);

// Parameters to pass to the template
Map params = new HashMap();
params.put("__locale", preferredLocale);

request.setAttribute("title", contentTitle);

// Include template head
cms.includeTemplatePart(template, "head", params);
%>
<section class="article-hero">
    <div class="article-hero-content">
        <h1><%= contentTitle %></h1>
        <figure>
            <%= ImageUtil.getImage(cms, imgUri) %>
            <figcaption><%= cms.property("byline", imgUri, "") %></figcaption>
        </figure>
    </div>
</section>
<%= content %>
<%
// Include error details?
if (cms.showException()) { // Returns true if the current user has the "DEVELOPER" role and can view the exception stacktrace
    out.println("<section class=\"paragraph\">");
    out.println("<p>");
    out.println("Handler was " + cms.getRequestContext().getUri() + "<br />");
    out.println("Requested page was " + requestedPageUri + "<br />");
    out.println("Image was " + imgUri + ", which did " + (cms.getCmsObject().existsResource(imgUri) ? "" : "NOT") + " exist");
    out.println("</p>");
    if (cms.getErrorMessage() != null) {
        cms.keyStatus("error_description");
        // print the error message for developers, if available
        out.print("<p><b>" + cms.getErrorMessage() + "</b></p>");
    }

    if (cms.getException() != null) {
        // print the exception for developers, if available
%>
        <p><strong><%= cms.getException() %></strong></p>
        <p></p>
        <pre>
        <% cms.getException().printStackTrace(new java.io.PrintWriter(out)); %>
        </pre>
<% 
    }
    out.println("</section>");
}


// Include template foot
cms.includeTemplatePart(template, "foot", params);

// write the exception to the opencms.log, if present
cms.logException();

// set the original error status code for the returned page
Integer status = cms.getStatusCode();
if (status != null) {
    cms.setStatus(status.intValue());
}
%>