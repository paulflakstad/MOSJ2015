<%-- 
    Document   : indicators-feed
    Description: Outputs a JSON file describing MOSJ indicator pages matching a
                    search query, given by the "q" parameter. Uses JSONP if a 
                    "callback" parameter is present.
    Created on : May 5, 2015, 1:59:57 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="org.opencms.main.*, 
            org.opencms.search.*, 
            org.opencms.util.CmsStringUtil,
            org.opencms.search.fields.*, 
            org.opencms.file.*, 
            org.opencms.flex.CmsFlexController,
            org.opencms.jsp.*, 
            java.util.*" 
%><%    
    // Create a JSP action element
    CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    
    // We expect 1 or 2 parameters: 
    //  1) the required query string ("q")
    //  2) the optional name of the callback function ("callback")
    String query = cms.getRequest().getParameter("q");
    String callback = cms.getRequest().getParameter("callback");
    
    // Determine the MIME sub-type by checking if a "callback" parameter exists
    String mimeSubType = "json";
    if (callback != null && !callback.isEmpty()) {
        mimeSubType = "javascript";
    }
    // Important: Set this as early as possible! ("application/json" OR "application/javascript")
    CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/" + mimeSubType + "; charset=utf-8");
    
    // Widen the query
    try {
        if (!query.endsWith("*")) {
            query = "(" + query + ") OR (" + query.concat("*") + ")";
        }
    } catch (Exception e) {}
    
    //CmsSearchManager searchManager = OpenCms.getSearchManager();
    //String resourceUri = cms.getRequestContext().getUri();
    //String folderUri = cms.getRequestContext().getFolderUri();
    Locale locale = cms.getRequestContext().getLocale();
    String loc = locale.toString();
    
    // Determine the default index name (used if no index name is set on the "search.index" property)
    final String DEFAULT_INDEX_NAME = "MOSJ_" + loc + "_online"; // = "MOSJ_no_online" OR "MOSJ_en_online"
    
    //
    // Generate the output by querying the search index and handling the result
    //
    try {
        CmsSearch search = new CmsSearch();
        search.init(cms.getCmsObject());
        search.setMatchesPerPage(30);
        search.setDisplayPages(1);
        //search.setQuery(query);
        //search.init(cms.getCmsObject());
        try {
            search.getIndex(); 
        } catch (NullPointerException npe) {
            // No index name set - read it from the 'search.index' property, fallback to default
            search.setIndex(cms.property("search.index", "search", DEFAULT_INDEX_NAME));
        }

        //String fields = search.getFields();
        //String fields = "title content";
        //fields = "*";
	
        //search.setField(new String[] { "content", "title", "description", "keywords" });
        //search.setField(new String[] { "title", "description", "keywords", "content" });
        //search.setField(new String[] { CmsSearchField.FIELD_SORT_TITLE, CmsSearchField.FIELD_KEYWORDS, CmsSearchField.FIELD_DESCRIPTION, CmsSearchField.FIELD_CONTENT });
        search.setField(new String[] { "title", "title-key", "keywords", "content" });
        search.setQuery(query);

        List result = null;
        try {
             result = search.getSearchResult();
        }
        catch (java.lang.NullPointerException npe) {
            out.println("{ \"responseCode\": 500, \"message\": \"Error\" }");
            return;
        }
        
        // If there were no results, do a fuzzy search
        if (search.getSearchResultCount() <= 0) {
            query = cms.getRequest().getParameter("q");
            if (!query.endsWith("~")) {
                query = "(" + query + ") OR (" + query.concat("~") + ")";
            }
            search.setQuery(query);
            try {
                result = search.getSearchResult();
            }
            catch (java.lang.NullPointerException npe) {
                out.println("{ \"responseCode\": 500, \"message\": \"Error\" }");
                return;
            }
        }

        if (callback != null && !callback.isEmpty()) {
            out.println(callback + "(");
        }
        
        out.print("[");
        
        if (result != null && !result.isEmpty()) {
            ListIterator iterator = result.listIterator();
            while (iterator.hasNext()) {
                out.print("{");
                try {
                    CmsSearchResult entry = (CmsSearchResult)iterator.next();
                    String entryPath = cms.link(cms.getRequestContext().removeSiteRoot(entry.getPath()));
                    out.print(" \"title\": \"" + entry.getField(CmsSearchField.FIELD_TITLE) + "\",");
                    out.print(" \"uri\": \"" + entryPath + "\"");
                } catch (Exception e) {
                    out.print(" \"error\" : \"" + e.getMessage() + "\"");
                }
                out.print("}");
                if (iterator.hasNext()) {
                    out.print(",");
                }
            }
        }
        else {
            //out.print("{ \"message\": \"No results for '" + search.getQuery() + "'\" }");
        }
        
        out.println("]");
        
        if (callback != null && !callback.isEmpty()) {
            out.println(")");
        }
        
    } catch (Exception e) {
        out.println("{ \"responseCode\": 500, \"message\": \"" + e.getMessage() + "\" }");
        return;
    }
%>