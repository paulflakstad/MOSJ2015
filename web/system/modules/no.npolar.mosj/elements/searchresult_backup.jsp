<%-- 
    Document   : searchresult.jsp - DEPRECATED / OLD / TEST
    Created on : May 5, 2015, 10:26:13 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page buffer="none" 
             import="org.opencms.main.*, 
             org.opencms.search.*, 
             org.opencms.search.fields.*, 
             org.opencms.file.*, 
             org.opencms.jsp.*, 
             java.util.*" 
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"%>
<%    
    // Create a JSP action element
    org.opencms.jsp.CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // Get the search manager
    CmsSearchManager searchManager = OpenCms.getSearchManager();
    String resourceUri = cms.getRequestContext().getUri();
    String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
    final String DEFAULT_INDEX_NAME = "MOSJ_" + loc + "_online"; // E.g. "MOSJ_no_online"
    
    String query = cms.getRequest().getParameter("query");
    
    CmsSearch search = new CmsSearch();
    search.setField(new String[] { "title", "description", "keywords", "content" });
    search.setMatchesPerPage(20);
    search.setDisplayPages(-1);
    search.setQuery(query);
    search.init(cms.getCmsObject());
    try {
        search.getIndex();
    } catch (NullPointerException npe) {
        // No index name set - read it from the 'search.index' property, fallback to default
        search.setIndex(cms.property("search.index", "search", DEFAULT_INDEX_NAME));
    }
%>

<jsp:useBean id="search" scope="request" class="org.opencms.search.CmsSearch">
    <jsp:setProperty name="search" property="matchesPerPage" param="matchesperpage"/>
    <jsp:setProperty name="search" property="displayPages" param="displaypages"/>
    <jsp:setProperty name="search" property="*"/>
    <% 
    	search.init(cms.getCmsObject());
        try {
            search.getIndex(); 
        } catch (NullPointerException npe) {
            // No index name set - read it from the 'search.index' property, fallback to default
            search.setIndex(cms.property("search.index", "search", DEFAULT_INDEX_NAME));
        }
    %>
</jsp:useBean>
<section class="serp" style="padding-top:2em;">
<%
    int resultno = 1;
    int pageno = 0;
    if (request.getParameter("searchPage") != null) {		
        pageno = Integer.parseInt(request.getParameter("searchPage")) - 1;
    }
    resultno = (pageno * search.getMatchesPerPage()) + 1;

    //String fields = search.getFields();
    String fields = "title content";
    
    if (fields == null) {
   	fields = request.getParameter("fields");
    }

    List result = null;
    try {
         result = search.getSearchResult();
    }
    catch (java.lang.NullPointerException npe) {
        out.println("<h2>Script crashed!</h2>"
                + "<p>A null pointer was encountered while attempting to process the search results. The cause may be an invalid or missing search index. "
                + " (This search used the index '" + search.getIndex() + "'.)"
                + "</p>"
                + "<p>Please notify the system administrator.</p>");
        StackTraceElement[] npeStack = npe.getStackTrace();
        if (npeStack.length > 0) {
            out.println("<h3>Stack trace:</h3>"); //npe.printStackTrace(response.getWriter());
            out.println("<span style=\"display:block; width:auto; overflow:scroll; font-style:italic; color:red; border:1px dotted #555; background-color:#ddd; padding:5px;\">");
            out.println("java.lang.NullPointerException:<br>");
            for (int i = 0; i < npeStack.length; i++) {
                out.println(npeStack[i].toString());
            }
            out.println("</span>");
        }
    }
	// DEBUG:
	/*
	out.println("<h4>Fields: " + fields + "</h4>");
	out.println("<h4>Resultno: " + resultno + "</h4>");
	out.println("<h4>Pageno: " + pageno + "</h4>");
	out.println("<h4>Result (List): " + result + "</h4>");
	*/
	
    if (result == null) {
        if (search.getLastException() != null) { 
            out.println("<h2>Error</h2>" + search.getLastException().toString());
        }
    } 
    else {
        ListIterator iterator = result.listIterator();
        %>
        <h2 class="serp-num-hits"><%= search.getSearchResultCount() %><%= (loc.equalsIgnoreCase("no") ? 
        " treff for " : " hits for ")%><i><%= search.getQuery()%></i></h2>
        <%
        while (iterator.hasNext()) {
            CmsSearchResult entry = (CmsSearchResult)iterator.next();
            String entryPath = cms.link(cms.getRequestContext().removeSiteRoot(entry.getPath()));
            %>
            
                <h3 class="searchHitTitle" style="padding:1em 0 0.2em 0; font-weight:bold;">
                    <a href="<%= entryPath %>"><%= entry.getField(CmsSearchField.FIELD_TITLE) %></a>
                </h3>
            
                <div class="text">
                    <%= entry.getExcerpt() %>
                </div>
            
                <div class="search-hit-path" style="font-size:0.7em; color:green;">
                    <%= "http://" + request.getServerName() + entryPath %>
                </div>
            
				
            <%
            resultno++;            
        }
    }
%> 
    <nav class="pagination clearfix" style="margin-top:2em; margin-bottom:2em;">
        <div class="pagePrevWrap">
<%
            if (search.getPreviousUrl() != null) {
%>
                <!--<input type="button" value="&lt;&lt; <%= (loc.equalsIgnoreCase("no") ? "forrige" : "previous") %>" onclick="location.href='<%= cms.link(search.getPreviousUrl()) %>&fields=<%= fields %>';">-->
                <a class="prev" title="<%= (loc.equalsIgnoreCase("no") ? "Forrige" : "Previous") %>" href="<%= cms.link(search.getPreviousUrl()) %>&fields=<%= fields %>"></a>
<%
            } else {
%>
                <a class="prev inactive"></a>
<%
            }
%>
        </div>
        <div class="pageNumWrap">
<%        
    Map pageLinks = search.getPageLinks();
    Iterator i =  pageLinks.keySet().iterator();
    while (i.hasNext()) {
        int pageNumber = ((Integer)i.next()).intValue();
        String pageLink = cms.link((String)pageLinks.get(new Integer(pageNumber)));       		
        if (pageNumber != search.getSearchPage()) {
%>
            <a href="<%= pageLink %>&fields=<%= fields %>"><%= pageNumber %></a>
<%
        } else {
%>
            <span class="currentpage"><%= pageNumber %></span>
<%
        }
    }
%>
        </div>
        <div class="pageNextWrap">
<%
    if (search.getNextUrl() != null) {
%>
            <a class="next" title="<%= (loc.equalsIgnoreCase("no") ? "Neste" : "Next") %>" href="<%= cms.link(search.getNextUrl()) %>&fields=<%= fields %>"></a>
<%
    } else { 
%>  
            <a class="next inactive"></a>
<%
    }
%>
        </div>
    </nav>
</section>