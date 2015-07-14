<%-- 
    Document   : optimized-css
    Created on : Jul 9, 2015, 10:12:56 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page session="false" import="com.alkacon.opencms.v8.weboptimization.CmsOptimizationCss, org.opencms.file.CmsObject, java.io.*, com.yahoo.platform.yui.compressor.*" %><%

CmsOptimizationCss c = new CmsOptimizationCss(pageContext, request, response);
try {
    //CmsObject cmso = c.getCmsObject();
    String cssOriginalContent = c.getContent(c.getRequestContext().getUri().replaceAll("(\\.(min||opt)\\.)", "."));//, "Resource/Path", new java.util.Locale("en"));
    //out.println("<!-- original css:\n" + cssOriginalContent + " -->");
    Reader reader = new BufferedReader(new StringReader(cssOriginalContent));
    try {
        // process the js code
        CssCompressor cssc = new CssCompressor(reader);
        //cssc.compress(c.getJspContext().getOut(), -1);
	cssc.compress(out, -1);
    } finally {
        try {
            reader.close();
        } catch (Exception ee) {
            throw ee;
        }
    }
    //c.optimizeCss(cssOriginalContent, );
} catch (Exception e) {
	out.println("/* Error: " + e.getMessage() + " */");
    //e.printStackTrace();
    org.opencms.main.CmsLog.getLog(CmsOptimizationCss.class).error(e.getMessage(), e);
    //throw e;
}
%>