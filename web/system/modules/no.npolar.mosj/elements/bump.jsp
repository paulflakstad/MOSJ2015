<%-- 
    Document   : bump
    Description: Helper for search box with suggestions. Issues a 301 redirect, if the given URI exists.
    Created on : May 5, 2015, 3:59:46 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent, org.opencms.jsp.CmsJspActionElement, org.opencms.util.CmsRequestUtil" 
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
// Get the navigation target (set as a parameter value)
String navTarget = request.getParameter("uri");
String redirAbsPath = null;

if (navTarget == null) {
    out.println("No navigation target supplied.");
    return;
}
// Navigation target is empty, redirect back
if (navTarget.isEmpty()) {
    try {
        navTarget = request.getParameter("ref") != null ? request.getParameter("ref") : "/";
    } catch (Exception e) {
        out.println("Something went terribly wrong during navigation to '" + navTarget + "'.");
        return;
    }
}
else if (!navTarget.startsWith("/")) {
    out.println("Navigation target '" + navTarget + "' is not a local resource.");
    return;
}

// All should be OK. Redirect.
redirAbsPath = request.getScheme() + "://" + request.getServerName() + navTarget;
//CmsRequestUtil.redirectPermanently(cms, redirAbsPath);// Flawed, sends 302
cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
%>