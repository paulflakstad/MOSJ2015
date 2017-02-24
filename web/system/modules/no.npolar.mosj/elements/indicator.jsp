<%-- 
    Document   : indicator
    Description: Template for OpenCms files of type "mosj_indicator" (MOSJ indicator).
    Created on : Dec 10, 2014, 1:30:18 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.file.types.CmsResourceTypePointer"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils,
            org.opencms.util.CmsHtmlExtractor,
            org.opencms.jsp.*,
            org.opencms.file.*,
            org.opencms.main.*,
            org.opencms.xml.*,
            org.opencms.json.*,
            org.opencms.util.CmsRequestUtil,
            org.opencms.util.CmsStringUtil,
            java.io.PrintWriter,
            java.net.HttpURLConnection,
            java.net.URL,
            java.net.URLEncoder,
            java.text.SimpleDateFormat,
            java.util.*,
            org.opencms.security.*,
            no.npolar.util.*,
            no.npolar.data.api.*,
            no.npolar.data.api.mosj.*,
            no.npolar.data.api.util.APIUtil" pageEncoding="UTF-8" session="true"
%><%!
public JSONObject createOverrideConfig(List<String> globalOverrides, Map<String, List<String>> individualOverrides) {
    try {
        JSONObject json = new JSONObject("{}");
        Iterator<String> iGlobal = globalOverrides.iterator();
        while (iGlobal.hasNext()) {
        }
        return json;
    } catch (Exception e) {
        
    }
    return null;
}

public String getLinkListHtml(I_CmsXmlContentContainer linkList, CmsAgent cms) throws JspException {
	
    String listHtml = "";
    try {
        if (linkList.hasMoreResources()) {
            I_CmsXmlContentContainer linkItems = cms.contentloop(linkList, "LinkListLink");
            while (linkItems.hasMoreResources()) {
                String itemTitle = cms.contentshow(linkItems, "Title");
                String itemUri = cms.contentshow(linkItems, "URI");
                if (CmsAgent.elementExists(itemTitle)) {
                    listHtml += "<li>";
                    if (CmsAgent.elementExists(itemUri)) {
                        listHtml += "<a href=\"" + itemUri + "\">" + itemTitle + "</a>";
                    } else {
                        listHtml += itemTitle;
                    }
                    listHtml += "</li>";
                }
            }
        }
        if (!listHtml.isEmpty()) {
            return "<ul>" + listHtml + "</ul>";
        }
        /*while (linkList.hasMoreResources()) {
            String itemTitle = cms.contentshow(linkList, "LinkListLink/Title");
            String itemUri = cms.contentshow(linkList, "LinkListLink/URI");
            if (CmsAgent.elementExists(itemTitle)) {
                listHtml += "<li>";
                if (CmsAgent.elementExists(itemUri)) {
                    listHtml += "<a href=\"" + itemUri + "\">" + itemTitle + "</a>";
                } else {
                    listHtml += itemTitle;
                }
                listHtml += "</li>";
            }
        }
        if (!listHtml.isEmpty()) {
            return "<ul>" + listHtml + "</ul>";
        }*/
    } catch (Exception e) {
        // Handle this?
    }
    return listHtml;
}

public String getDefinitionListItem(String title, String data, boolean preTaggedData)  {
    return "<dt>" + title + "</dt>\n" + (preTaggedData ? "" : "<dd>") + data + (preTaggedData ? "" : "</dd>");
}

/**
 * Determine if the given URL identifies something that should open in a new
 * tab / window (target="_blank").
 * 
 * @param url  The URL to evaluate.
 * @return True if the URL identifies something that should open in a new tab / window, false if not.
 */
public boolean isTargetBlank(String url) {
    if (url == null || url.trim().isEmpty())
        return false;
    return url.contains("//svalbardkartet.npolar.no/") 
            || url.contains("//toposvalbard.npolar.no/")
            || url.endsWith(".pdf") || url.endsWith(".PDF");
}

public String createLinkList(I_CmsXmlContentContainer linksContainer, String elementName, CmsAgent cms, boolean asDefinitionDataItems, String defaultItemContent) {
    String linkItems = "";
    String linkItemTag = asDefinitionDataItems ? "dd" : "li";
    try {
        //if (linksContainer.hasMoreResources()) {
            I_CmsXmlContentContainer itemsContainer = cms.contentloop(linksContainer, elementName);
            while (itemsContainer.hasMoreResources()) {

                String linkText = cms.contentshow(itemsContainer, "Text");
                String linkUrl = cms.contentshow(itemsContainer, "URL");
                String linkComment = cms.contentshow(itemsContainer, "Comment");

                if (CmsAgent.elementExists(linkText) || CmsAgent.elementExists(linkUrl)) {
                    linkItems += "\n<" + linkItemTag + " class=\"parameter-meta-data\">";
                    if (CmsAgent.elementExists(linkUrl)) {
                        // Enforce lang=en for Placenames links in English-language pages
                        if (linkUrl.contains("//placenames.npolar.no/") && !cms.getRequestContext().getLocale().toString().equals("no") && !linkUrl.contains("lang=en")) {
                            linkUrl = CmsRequestUtil.appendParameter(linkUrl, "lang", "en");
                        }
                        // Ensure proper escaping of special characters like "&"
                        linkUrl = CmsStringUtil.escapeHtml(StringEscapeUtils.unescapeXml(linkUrl));
                        linkItems += "<a href=\"" + linkUrl + "\"" + (isTargetBlank(linkUrl) ? " target=\"_blank\"" : "") + ">";
                        if (!CmsAgent.elementExists(linkText))
                            linkItems += linkUrl;
                    }

                    if (CmsAgent.elementExists(linkText)) {
                        linkItems += linkText;
                    }
                    if (CmsAgent.elementExists(linkUrl)) {
                        linkItems += "</a>";
                    }
                    if (CmsAgent.elementExists(linkComment)) {
                        linkItems += "<p>" + linkComment + "</p>";
                    }

                    linkItems += "</" + linkItemTag + ">";
                }
            }
        //}
    } catch (Exception e) {
        linkItems += "<!--\n" + e.getMessage() + "\n-->";
    }
    
    
    if (linkItems.isEmpty() && defaultItemContent != null) {
        linkItems += "<" + linkItemTag + " class=\"parameter-meta-data parameter-meta-data-default\">" + defaultItemContent + "</" + linkItemTag + ">";
    }
    
    if (!linkItems.isEmpty()) {
        if (asDefinitionDataItems)
            return linkItems;
        else
            return "<ul>" + linkItems + "\n</ul>";
    }
    
    return "";
}

public void printParameterDetailsAsComments(TimeSeriesCollection tsc, MOSJService service, CmsJspActionElement cms) {
    try {
        PrintWriter out = cms.getResponse().getWriter();
        // Print parameter details as html comments
        if (true) {
            List<TimeSeries> tss = tsc.getTimeSeries();
            if (tss != null && !tss.isEmpty()) {
                out.println("\n<!-- \nChart for parameter " + tsc.getURL() + "\nTime series in this chart:");
                Iterator<TimeSeries> i = tss.iterator(); 
                while (i.hasNext()) {
                    TimeSeries ts = i.next();
                    out.println("\n\t\t" + ts.getTitle() + " " + ts.getURL(service) + " - " + service.getServiceBaseURL() + "timeseries/" + ts.getId());
                }
                out.println("\n-->");
            }
        }
    } catch (Exception ignore) {}
}

/**
 * Gets a cite string for the given time series collection.
 * <p>
 * The publish year will be the current year, and the publisher will be MOSJ. A
 * link to this indicator page will also be included.
 * 
 * @param cms A properly initialized CmsAgent, used to produce links, labels, etc.
 * @param tsc The time series collection to cite.
 * @return A cite string.
 */
public String getCiteString(CmsAgent cms, TimeSeriesCollection tsc) {
    //String loc = cms.getRequestContext().getLocale().getLanguage();
    String mosj = cms.labelUnicode("label.mosj.global.sitename").concat(" (MOSJ)");
    try { mosj = CmsHtmlExtractor.extractText(mosj, "UTF-8"); } catch (Exception e) {}

    String s = tsc.getAuthorsStr()
            // Time series have no "published year" field yet, so for now we 
            // just use the current year
            + " (" + new GregorianCalendar().get(Calendar.YEAR) + "). "
            + tsc.getTitle() + ". "
            + mosj + ". URL: "
            + OpenCms.getLinkManager().getOnlineLink(
                    cms.getCmsObject(), 
                    cms.getRequestContext().getUri()
            );

    return s;
}

/**
 * Tries to lookup an organization name, based on the organization ID.
 * <p>
 * E.g. given "npolar.no" as ID, should return "Norwegian Polar Institute".
 * <p>
 * The lookup is done by reading the title of VFS resource /[no|en]/org/[id]
 * which must be of type "pointer".
 */
public String lookupNameForId(String id, CmsAgent cms, Locale inLocale) {
    String name = id + " " + TimeSeries.AUTHOR_NAME_UNKNOWN; // Same as in TimeSeries
    CmsObject cmso = cms.getCmsObject();
    try {
        CmsResource orgRes = cmso.readResource(
                "/"+inLocale.toString()+"/org/"+id, 
                CmsResourceFilter.ALL.addRequireType(CmsResourceTypePointer.getStaticTypeId())
        );
        name = cmso.readPropertyObject(orgRes, "Title", false).getValue(id);
    } catch (Exception e) {
        // no such resource...
    }
    return name;
}
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();

String lastUpdated         = null;
SimpleDateFormat dateFormat = new SimpleDateFormat(cms.label("label.mosj.global.dateformat.dmy"), locale);
Long lastUpdatedRaw         = Long.valueOf(cmso.readPropertyObject(requestFileUri, "updated", false).getValue("0"));

try {
    if (lastUpdatedRaw > 0) {
        lastUpdated = dateFormat.format(new Date(lastUpdatedRaw));
        lastUpdated = cms.label("label.mosj.indicator.data-last-updated") + " " + lastUpdated;
    }
} catch (Exception e) {}

final String PARAGRAPH_HANDLER      = "../../no.npolar.common.pageelements/elements/paragraphhandler.jsp";

// Localized labels
final String LABEL_STATUS_TRENDS = cms.labelUnicode("label.mosj.indicator.status-trends");// loc.equalsIgnoreCase("no") ? "Status / trend" : "Status / trend";
final String LABEL_CAUSAL_FACTORS = cms.labelUnicode("label.mosj.indicator.causal-factors");// loc.equalsIgnoreCase("no") ? "Årsaker / bakgrunn" : "Causal factors / background";
final String LABEL_CONSEQUENCES = cms.labelUnicode("label.mosj.indicator.consequences");//loc.equalsIgnoreCase("no") ? "Konsekvenser" : "Consequences";
final String LABEL_ABOUT = cms.labelUnicode("label.mosj.indicator.about-the-monitoring");//loc.equalsIgnoreCase("no") ? "Om overvåkingen" : "About the monitoring";
final String LABEL_PLACES = cms.labelUnicode("label.mosj.indicator.places-and-areas");// loc.equalsIgnoreCase("no") ? "Steder og områder" : "Places and areas";
final String LABEL_RELATED_MONITORING = cms.labelUnicode("label.mosj.indicator.relation-other-monitoring");//loc.equalsIgnoreCase("no") ? "Forhold til annen overvåking" : "Relation to other monitoring";
final String LABEL_RELATED_MONITORING_PROGRAMME = cms.labelUnicode("label.mosj.indicator.monitoring-programme");// loc.equalsIgnoreCase("no") ? "Overvåkingsprogram" : "Monitoring programme";
final String LABEL_RELATED_MONITORING_AGREEMENT = cms.labelUnicode("label.mosj.indicator.environmental-agreements");// loc.equalsIgnoreCase("no") ? "Internasjonale miljøavtaler" : "International environmental agreements";
final String LABEL_RELATED_MONITORING_COOPERATION = cms.labelUnicode("label.mosj.indicator.international-cooperation");//loc.equalsIgnoreCase("no") ? "Frivillig internasjonalt samarbeid" : "Voluntary international cooperation";
final String LABEL_RELATED_MONITORING_RELATED = cms.labelUnicode("label.mosj.indicator.related-monitoring"); // loc.equalsIgnoreCase("no") ? "Relatert overvåking" : "Related monitoring";
final String LABEL_RELATED_MONITORING_OTHER = cms.labelUnicode("label.mosj.indicator.related-monitoring-other");// loc.equalsIgnoreCase("no") ? "Annet" : "Other";
final String LABEL_RELATED_MONITORING_NONE = cms.labelUnicode("label.mosj.indicator.related-monitoring-none");// loc.equalsIgnoreCase("no") ? "Ingen" : "None";


final String LABEL_MONITORED_TITLE = cms.labelUnicode("label.mosj.indicator.monitored-title");// loc.equalsIgnoreCase("no") ? "Hva overvåkes?" : "What is being monitored?";
final String LABEL_TABLE_FORMAT = cms.labelUnicode("label.mosj.indicator.data-table");//loc.equalsIgnoreCase("no") ? "Data" : "Data";
final String LABEL_DATA_FILES = cms.labelUnicode("label.mosj.indicator.data-files");
final String LABEL_JSON_LINK = cms.labelUnicode("label.mosj.indicator.data-json");// loc.equalsIgnoreCase("no") ? "Maskinlesbart format (JSON)" : "Machine-readable format (JSON)";
final String LABEL_JSON_LINK_DESCR = cms.labelUnicode("label.mosj.indicator.data-json-descr");
final String LABEL_CSV_LINK = cms.labelUnicode("label.mosj.indicator.data-csv");// loc.equalsIgnoreCase("no") ? ".csv (kommaseparert)" : ".csv (comma-separated)";
final String LABEL_CSV_LINK_DESCR = cms.labelUnicode("label.mosj.indicator.data-csv-descr");
final String LABEL_XLS_LINK = cms.labelUnicode("label.mosj.indicator.data-xls");// loc.equalsIgnoreCase("no") ? ".xls (Excel)" : ".xls (Excel)";
final String LABEL_XLS_LINK_DESCR = cms.labelUnicode("label.mosj.indicator.data-xls-descr");
final String LABEL_DETAILS = cms.labelUnicode("label.mosj.indicator.data-details");// loc.equalsIgnoreCase("no") ? "Detaljer om disse dataene" : "Details on this data";
final String LABEL_CITE = cms.labelUnicode("label.mosj.indicator.cite");

final String LABEL_METHOD = cms.labelUnicode("label.mosj.indicator.data-method");// loc.equalsIgnoreCase("no") ? "Metode" : "Method";
final String LABEL_QUALITY = cms.labelUnicode("label.mosj.indicator.data-quality"); // loc.equalsIgnoreCase("no") ? "Kvalitet" : "Quality";
final String LABEL_OTHER_METADATA = cms.labelUnicode("label.mosj.indicator.data-other-metadata");// loc.equalsIgnoreCase("no") ? "Andre metadata" : "Other metadata";
final String LABEL_REFERENCE_LEVEL = cms.labelUnicode("label.mosj.indicator.data-reference-level");// loc.equalsIgnoreCase("no") ? "Referansenivå og tiltaksgrense" : "Reference level and inititive threshold";

final String LABEL_UPDATE_INTERVAL = cms.labelUnicode("label.mosj.indicator.data-update-interval");// loc.equalsIgnoreCase("no") ? "Oppdateringsintervall" : "Update interval";
final String LABEL_LAST_UPDATED = cms.labelUnicode("label.mosj.indicator.data-last-updated");// loc.equalsIgnoreCase("no") ? "Sist oppdatert" : "Last updated";
final String LABEL_NEXT_UPDATE = cms.labelUnicode("label.mosj.indicator.data-next-update");// loc.equalsIgnoreCase("no") ? "Neste oppdatering" : "Next update";
final String LABEL_AUTHORATIVE_INSTITUTION = cms.labelUnicode("label.mosj.indicator.data-autorative-institution");// loc.equalsIgnoreCase("no") ? "Oppdragsgivende institusjon" : "Authorative institution";
final String LABEL_EXECUTIVE_INSTITUTION = cms.labelUnicode("label.mosj.indicator.data-executive-institution");// loc.equalsIgnoreCase("no") ? "Utførende institusjon" : "Executive institution";
final String LABEL_CONTACT_PERSON = cms.labelUnicode("label.mosj.indicator.data-contact-person");// loc.equalsIgnoreCase("no") ? "Kontaktpersoner" : "Contact persons";

final String LABEL_FURTHER_READING = cms.labelUnicode("label.mosj.indicator.further-reading");
final String LABEL_LINKS = cms.labelUnicode("label.mosj.indicator.links"); //loc.equalsIgnoreCase("no") ? "Lenker" : "Links";
final String LABEL_REFERENCES = cms.labelUnicode("label.mosj.indicator.publications");// loc.equalsIgnoreCase("no") ? "Publikasjoner" : "Publications";

final String LABEL_CHART_LOAD = cms.labelUnicode("label.mosj.indicator.chart-loading");//loc.equalsIgnoreCase("no") ? "Laster graf&nbsp;&hellip;" : "Loading chart&nbsp;&hellip;";
final String LABEL_CHART_ERROR = loc.equalsIgnoreCase("no") ? 
                                    "Kan ikke vise grafen.</p><p class=\"placeholder-element-text-extra\">Prøv å laste inn siden på nytt. Du kan også <a href=\"/no/om/kontakt.html\">sende oss en feilmelding</a> hvis denne feilen vedvarer." 
                                    : 
                                    "Unable to display chart.</p><p class=\"placeholder-element-text-extra\">Try reloading the page. Please <a href=\"/en/about/contact.html\">report this error</a> should the problem persist.";

// Session storage for HighCharts configuration strings (javascript)
cms.getRequest().setAttribute("hcConfs", new HashMap<String, String>());

// Set the html document's title
String htmlDocTitle = cms.property("Title", requestFileUri, "");
cms.getRequest().setAttribute("title", htmlDocTitle);

cms.include(cms.getTemplate(), "head");

I_CmsXmlContentContainer structuredContent = cms.contentload("singleFile", requestFileUri, false);
//I_CmsXmlContentContainer copyStructContent = structuredContent;
while (structuredContent.hasMoreResources()) {
    
    String title = cms.contentshow(structuredContent, "Title");
    String latinName = cms.contentshow(structuredContent, "LatinName");
    String summary = cms.contentshow(structuredContent, "Summary");
    String imgUri = cms.contentshow(structuredContent, "Image");
    
    if (CmsAgent.elementExists(latinName)) {
        if (!latinName.trim().isEmpty())
            title = title + " <span class=\"scientific-name\">(" + latinName + ")</span>";
    }
    %>
    <h1 class="main-article__title"><span class="textwrap"><%= title %></span></h1>
    <%
    
    if (cms.elementExists(imgUri)) {
    %>
    
    
    <div class="article-hero hero hero--top main-article__hero">
        <div class="article-hero-content hero__content">
            <!--<h1><%= title %></h1>-->
            <figure>
                <!--<img src="<%= cms.link(imgUri) %>" alt="" />-->
                <%= ImageUtil.getImage(cms, imgUri) %>
                <figcaption><span class="credit"><%= cms.property("byline", imgUri, "") %></span></figcaption>
            </figure>            
        </div>
    </div>
    <%
    }
    %>
    <section class="descr main-article__descr">
        <% if (lastUpdated != null) { %>
        <div class="metadata metadata--page-data"><span class="metadata__timestamp"><%= lastUpdated %></span></div> 
        <% } %>
        <%= summary %>
    </section>
	
    <%
    ResourceBundle labels = ResourceBundle.getBundle(no.npolar.data.api.Labels.getBundleName(), locale);
    // Create and test service
    MOSJService service = new MOSJService(locale, cms.getRequest().isSecure());
    int responseCode = -1;
    boolean validResponseCode = false;
    final int TIMEOUT = 10000; // milliseconds

    try {
        URL url = new URL(service.getServiceBaseURL().concat("?q="));
        HttpURLConnection connection = (HttpURLConnection)url.openConnection();
        connection.setRequestMethod("GET");
        connection.setReadTimeout(TIMEOUT);
        connection.connect();
        responseCode = connection.getResponseCode();
    } catch (Exception e) {
    } finally {
        validResponseCode = responseCode == 200;
    }
    
    
    I_CmsXmlContentContainer mosjMonitoringData = cms.contentloop(structuredContent, "MonitoringData");
    int monitoringDataLoopCount = 0;
    while (mosjMonitoringData.hasMoreResources()) {
        monitoringDataLoopCount++;
        String parameterDetailsSectionId = "p-details-" + (monitoringDataLoopCount);
        
        String titleOverride = cms.contentshow(mosjMonitoringData, "Title");
        
        if (monitoringDataLoopCount == 1) {
        %>
        <section class="paragraph clearfix">
        <h2 id="parametere"><%= LABEL_MONITORED_TITLE %></h2>
        <%
        }
        // ToDo: "parameter-wrapper" (indicating one parameter is wrapped) is 
        //      misleading, since multiple parameters could be contained inside.
        %>
        <section class="toggleable open parameter-wrapper parameter-group">
        <%
        
        // 
        // Parameters
        // ==========
        //
        // The HTML output will be like this:
        //
        //  <parameter-group>    <-- Wraps 1-n parameters. They will share a title and details.
        //      <group title>    <-- Often the first parameter's title (auto-fetched), but should always be overridden if there are multiple charts in one wrapper
        //      <figure(s)>      <-- 1-N charts (interactive or just image)
        //          <figcaption> <-- Caption. One per chart.
        //          <data>       <-- Section for "raw data" (table + file links). One per chart.
        //      <details>        <-- adding details will trigger the parameter wrapper to close
        //  </parameter-group>   <-- Wrapper end - triggered either by existing details OR by the loop ending
        // 
        //  <parameter-group>    <-- Next wrapper (and so on)
        //      ...
        //
        // Each parameter hooks into the API via a parameter ID (old version), 
        // or via a set of time series IDs (new version). Either way, this 
        // ultimatetly gives us a way into the API, allowing us to pull the time 
        // series data we're interested in.
        // 
        // Custom settings can be applied to any chart, both chart-wide and per 
        // time series.
        //
        // See also the backing classes in the no.npolar.data.api library, in
        // particular MOSJService and TimeSeriesCollection.
        //
        I_CmsXmlContentContainer mosjParameters = cms.contentloop(mosjMonitoringData, "Parameter");
            
        int parametersLoopCount = 0; // Parameter counter
            
        while (mosjParameters.hasMoreResources()) {
            parametersLoopCount++;
            TimeSeriesCollection tsc = null;
            
            //MOSJParameter mp = null;
            
            // Parameter ID (old version)
            String pid = cms.contentshow(mosjParameters, "ID");
            if (!CmsAgent.elementExists(pid)) {
                pid = null;
            }
            
            // Drop this check - there will be plenty of hints...
            //boolean validParameterId = pid.matches("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}");
            
            String parameterTitle = cms.contentshow(mosjParameters, "Title");
            // List to hold the set of time series in this chart/parameter
            List<String> tsIds = new ArrayList<String>(2);
            
            String citeString = null;
            
            HighchartsChart chart = null;
            
            // Chart alt text and caption
            String parameterChartAltText = cms.contentshow(mosjParameters, "ChartAltText");
            String parameterChartCaption = cms.contentshow(mosjParameters, "ChartCaption");
            
            // Image present?
            String parameterImageUri = cms.contentshow(mosjParameters, "Image");
            
            // IDs for the outer wrapper, figures and sections
            String parameterGroupSectionId = null;//= "p-" + pid; // ID for "group of parameters" section
            String parameterFigureContainerId = null;// = "p-figure-" + pid;// ID for "single parameter's figure container"
            String parameterDataSectionId = null;// = "p-data-" + pid; // ID for "single parameter's data section"
            
            String parameterFigureBody = null;
                    
            // Use image instead of dynamic chart?
            // (Rarely-used backup solution. A title override is required.)
            if (CmsAgent.elementExists(parameterImageUri)) {
                String imageHtml = null;
                if (CmsAgent.elementExists(parameterChartAltText)) {
                    imageHtml = ImageUtil.getImage(cms, parameterImageUri, parameterChartAltText);
                } else {
                    imageHtml = ImageUtil.getImage(cms, parameterImageUri);
                }
                parameterFigureBody = imageHtml;
                parameterFigureContainerId = null;
            }
            
            // Regular dynamic chart (no image)
            else {
            
                // ID validity check
                if (!validResponseCode) {
                //if (!validParameterId || !validResponseCode) {
                    parameterFigureBody = "<p>" + LABEL_CHART_ERROR + "</p>";
                    parameterFigureContainerId = null;
                    /*
                    // Issue a warning to the editor if the parameter ID is bad
                    if (loggedInUser && !validParameterId) { 
                        out.println("<script type=\"text/javascript\">"
                                       + "\nalert('CRITICAL ERROR: Parameter ID [" + pid + "] is invalid.');"
                                    + "\n</script>");
                    }
                    //*/
                } else {
                    // Chart customization
                    JSONObject customization = null;
                    try {
                        customization = new JSONObject("{}");
                        
                        I_CmsXmlContentContainer timeSeriesLoop = cms.contentloop(mosjParameters, "TimeSeries");
                        while (timeSeriesLoop.hasMoreResources()) {
                            String timeSeriesId = cms.contentshow(timeSeriesLoop, "TimeSeriesID");
                            
                            if (CmsAgent.elementExists(timeSeriesId)) {
                                tsIds.add(timeSeriesId);
                                // Add any custom settings
                                JSONObject seriesCustomization = new JSONObject("{ \"id\": \"" + timeSeriesId + "\" }");
                                
                                I_CmsXmlContentContainer settingsLoop = cms.contentloop(timeSeriesLoop, "Setting");
                                while (settingsLoop.hasMoreResources()) {
                                    seriesCustomization.put(
                                            cms.contentshow(settingsLoop, "Name"), 
                                            cms.contentshow(settingsLoop, "Value")
                                    );
                                }
                                if (seriesCustomization.length() > 1) {
                                    // => not just the time series ID => add it
                                    customization.append("series", seriesCustomization);
                                } 
                            }
                        }


                        I_CmsXmlContentContainer mosjChartCustomization = cms.contentloop(mosjParameters, "ChartCustomization");
                        if (mosjChartCustomization.hasMoreResources()) {

                            // Chart-wide customization
                            I_CmsXmlContentContainer customSettingsContainer = cms.contentloop(mosjChartCustomization, "ParameterCustomization");
                            while (customSettingsContainer.hasMoreResources()) {
                                customization.put(cms.contentshow(customSettingsContainer, "Name"), cms.contentshow(customSettingsContainer, "Value"));
                            }
                            //*
                            // OLD VERSION:
                            // Individual time series customization
                            I_CmsXmlContentContainer mosjTimeSeriesCustomizations = cms.contentloop(mosjChartCustomization, "TimeSeriesCustomization");
                            while (mosjTimeSeriesCustomizations.hasMoreResources()) {
                                JSONObject seriesCustomization = new JSONObject("{ \"id\": \"" + cms.contentshow(mosjTimeSeriesCustomizations, "TimeSeriesID") + "\" }");
                                
                                customSettingsContainer = cms.contentloop(mosjTimeSeriesCustomizations, "Setting");
                                while (customSettingsContainer.hasMoreResources()) {
                                    seriesCustomization.put(cms.contentshow(customSettingsContainer, "Name"), cms.contentshow(customSettingsContainer, "Value"));
                                }
                                customization.append("series", seriesCustomization);
                            }
                            //*/
                            //out.println("<!-- Customization json created:\n" + customization.toString() + "\n-->");
                        }
                    } catch (Exception e) {
                        out.println("<!-- ERROR processing time series / custom settings: " + e.getMessage());
                    }

                    try {
                        if (!validResponseCode) {
                            throw new Exception("Unable to access web service @ " + service.getServiceBaseURL());
                        }
                        // Read the MOSJ parameter from the API
                        //mp = service.getMOSJParameter(pid);
                        
                        // If hand-picked do exists, use them
                        if (!tsIds.isEmpty()) {
                            tsc = service.createTimeSeriesCollection(tsIds, parameterTitle);
                        } 
                        // Otherwise, use the old version with the parameter ID
                        else if (pid == null) {
                            throw new NullPointerException("Parameter ID is not set (null).");
                        } else {
                            tsc = service.get(pid).getTimeSeriesCollection();
                        }
                        
                        // Try to patch organizations with no name (only ID)
                        try {
                            for (TimeSeries ts : tsc.getTimeSeries()) {
                                List<Contributor> authors = ts.getAuthors();
                                
                                for (int iAuthors = 0; iAuthors < authors.size(); iAuthors++) {
                                    Contributor a = authors.get(iAuthors);
                                    
                                    if (a.hasId() 
                                            && a.getName().contains(TimeSeries.AUTHOR_NAME_UNKNOWN)) {
                                        // => name unknown (same as ID)
                                        a = new Contributor(
                                                a.getId(), 
                                                lookupNameForId(
                                                        a.getId(), 
                                                        cms, 
                                                        locale
                                                )
                                        );
                                        authors.remove(iAuthors);
                                        authors.add(iAuthors, a);
                                    }
                                }
                            }
                        } catch (Exception e) {
                            out.println("<!-- Unable to patch organization: " + e.getMessage() + " -->");
                        }
                        
                        try {
                            citeString = getCiteString(cms, tsc);
                        } catch (Exception e) {}
                        if (citeString != null && !citeString.isEmpty()) {
                            customization.put(
                                    HighchartsChart.OVERRIDE_KEY_CREDIT_TEXT, 
                                    "Data: " + tsc.getAuthorsStr()
                            );
                            customization.put(
                                    HighchartsChart.OVERRIDE_KEY_CREDIT_URI, 
                                    APIUtil.toApiUrl(tsc.getURL())
                                    //APIUtil.toApiUrl(tsc.getURL()).replaceFirst("api\\.npolar\\.no", "data.npolar.no")
                            );
                        }
                        
                        parameterFigureBody = LABEL_CHART_LOAD;
                        //printParameterDetailsAsComments(mp, service, cms);
                       
                        // Store the javascript that actually creates the chart.
                        // This script is printed out by the master template (to 
                        // get the code nearer the document end).
                        chart = new HighchartsChart(tsc, customization);
                        String chartConfig = chart.getChartConfigurationString();
                        
                        parameterGroupSectionId = "p-" + chart.getId();
                        parameterFigureContainerId = "p-figure-" + chart.getId();
                        parameterDataSectionId = "p-data-" + chart.getId();
                        
                        ((Map<String, String>)cms.getRequest().getAttribute("hcConfs")).put(parameterFigureContainerId, chartConfig);
                        
                    } catch (Exception e) {
                        out.println("<!-- \nERROR creating parameter / chart settings: " + e.getMessage() + "\n-->");
                    }
                    
                } // if (parameter ID was valid AND we had no trouble reading the API)
            } // if (dynamic chart)
            
            
            
            
            
            
            
            
            // ------------------------------
            // Output html for this parameter
            //
            
            if (parametersLoopCount == 1) { // => Do this only on first iteration
                
                // Construct the parameter group heading
                String displayTitle = null;
                try {
                    displayTitle = CmsAgent.elementExists(titleOverride) ? titleOverride : (tsc == null ? "[Parameter]" : tsc.getTitle());
                } catch (Exception ignore) {}
                
                // Print the heading and the parameter-group div, which wraps 1-n parameters/charts
                %>
                <h3 class="toggletrigger parameter-group-heading" aria-controls="<%= parameterGroupSectionId %>"><a href="#<%= parameterGroupSectionId %>"><%= displayTitle %></a></h3>
                <div class="toggletarget parameter-group-content" id="<%= parameterGroupSectionId %>">
                <%
            }
            
            boolean imageFigure = parameterFigureBody != null && parameterFigureBody.startsWith("<img ");
            
            %>
            <figure class="media">
    
                <div class="hc-chart"<%= (parameterFigureContainerId != null && !parameterFigureContainerId.isEmpty() ? " id=\"" +parameterFigureContainerId+"\"" : "") %>>
                <%
                if (!imageFigure) {
                %>
                    <div class="placeholder-element placeholder-element-chart">
                        <div class="placeholder-element-text">
                <% } %>
                <%= parameterFigureBody %>
                <%
                if (!imageFigure) {
                %>
                        </div>
                    </div>
                <% } %>

                </div>
                <%
                if (CmsAgent.elementExists(parameterChartAltText)) {
                %>
                <div class="element-alt-text">
                    <%= parameterChartAltText %>
                </div>
                <% 
                } 
                if (CmsAgent.elementExists(parameterChartCaption)) {
                %>
                <figcaption class="caption">
                    <%= parameterChartCaption %>
                </figcaption>
                <% } %>
            </figure>
            <%
            
            // Print data section for dynamic charts only
            //
            // ToDo: Fix URLs for file downloads - they will not work with the 
            // new "no parameter" approach. The export file must somehow be able 
            // to recreate the TimeSeriesCollection instance (because it holds 
            // the title) or equivalent. Pass the OpenCms UUID + XPath/details?
            //
            if (tsc != null) {
                try {
                    
                    String generalUri = "/data-export?locale=" + loc;
                    if (tsIds != null && !tsIds.isEmpty()) {
                        // Hand-picked time series IDs exist => new version
                        generalUri += 
                                "&amp;indicator=" 
                                + cmso.readResource(requestFileUri).getStructureId()
                                + "&amp;name=" 
                                + URLEncoder.encode(""+tsc.getTitle(), "UTF-8")
                                ;
                    } else {
                        generalUri += "&id=" + pid;
                    }
                    
                    
                    String xlsUri = cms.link(generalUri + "&amp;type=xlsx");
                    String csvUri = cms.link(generalUri + "&amp;type=csv");
                    %>
                    <div class="toggleable collapsed parameter-data-table-wrapper">
                        <a href="#<%= parameterDataSectionId %>" class="toggletrigger" aria-controls="<%= parameterDataSectionId %>"><i class="icon-grid"></i> <%= LABEL_TABLE_FORMAT %></a>
                        <div class="toggletarget" id="<%= parameterDataSectionId %>">
                            <div class="parameter-data-info">
                                <h4><%= LABEL_DATA_FILES %></h4>
                                <p>
                                    <a class="cta" href="<%= xlsUri %>" data-tooltip="<%= LABEL_XLS_LINK_DESCR %>">
                                        <i class="icon-download-alt"></i> <%= LABEL_XLS_LINK %>
                                    </a> 
                                    <a class="cta" href="<%= csvUri %>" data-tooltip="<%= LABEL_CSV_LINK_DESCR %>">
                                        <i class="icon-download-alt"></i> <%= LABEL_CSV_LINK %>
                                    </a>
                                    <a class="cta" href="<%= tsc.getURL() %>" data-tooltip="<%= LABEL_JSON_LINK_DESCR %>">
                                        <i class="icon-database"></i> <%= LABEL_JSON_LINK %>
                                    </a>
                                </p>
                            </div>
                            <div class="parameter-data-info">
                                <h4><%= LABEL_CITE %></h4>
                                <span class="cite-string" style="background: #fff; color: #000; padding:0.5em; font-size: smaller; display:block;"><%= citeString %></span>
                            </div>
                            <%
                            if (tsc.getTimeMarkersCount() < 500) {
                                out.println(tsc.getAsTable(chart.getId(), "responsive"));
                            }
                            %>
                        </div><!-- .toggletarget -->
                    </div><!-- .toggleable.parameter-data-table-wrapper -->
                    <%
                } catch (Exception e) {
                    out.println("<!-- \nERROR creating parameter data section: " + e.getMessage() + "\n-->");
                }
            }
            

        } // while (parameters)
        
        
        //
        // Monitoring data details
        //
        I_CmsXmlContentContainer mosjMonitoringDataDetails = cms.contentloop(mosjMonitoringData, "Details");
        if (mosjMonitoringDataDetails.hasMoreResources()) {
            StringBuilder detailsHtmlBuilder = new StringBuilder(512);
            String detailsHtml = "";

            String parameterLastUpdated = cms.contentshow(mosjMonitoringDataDetails, "LastUpdate");
            String parameterUpdateInterval = cms.contentshow(mosjMonitoringDataDetails, "UpdateInterval");
            String parameterNextUpdate = cms.contentshow(mosjMonitoringDataDetails, "NextUpdate");
            String parameterMethod = cms.contentshow(mosjMonitoringDataDetails, "Method");
            String parameterQuality = cms.contentshow(mosjMonitoringDataDetails, "Quality");
            String parameterOtherMetadata = cms.contentshow(mosjMonitoringDataDetails, "OtherMetadata");
            String parameterReferenceLevel = cms.contentshow(mosjMonitoringDataDetails, "ReferenceLevel");
            I_CmsXmlContentContainer parameterAuthorativeInstitutions = cms.contentloop(mosjMonitoringDataDetails, "AuthorativeInstitutions");
            I_CmsXmlContentContainer parameterExecutiveInstitutions = cms.contentloop(mosjMonitoringDataDetails, "ExecutiveInstitutions");
            I_CmsXmlContentContainer parameterContactPersons = cms.contentloop(mosjMonitoringDataDetails, "ContactPersons");

            // List on top of the details
            if (CmsAgent.elementExists(parameterLastUpdated)) {
                try {
                    parameterLastUpdated = dateFormat.format(new Date(Long.valueOf(parameterLastUpdated)));
                    detailsHtmlBuilder.append(getDefinitionListItem(LABEL_LAST_UPDATED, parameterLastUpdated, false));
                } catch (Exception e) {}
            }
            if (CmsAgent.elementExists(parameterUpdateInterval)) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_UPDATE_INTERVAL, parameterUpdateInterval, false));
            }
            if (CmsAgent.elementExists(parameterNextUpdate)) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_NEXT_UPDATE, parameterNextUpdate, false));
            }
            String authorativeInstitutionsList = createLinkList(mosjMonitoringDataDetails, "AuthorativeInstitutions", cms, true, null);
            //String authorativeInstitutionsList = getLinkListHtml(parameterAuthorativeInstitutions, cms);
            if (!authorativeInstitutionsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_AUTHORATIVE_INSTITUTION, authorativeInstitutionsList, true));
            }
            String executiveInstitutionsList = createLinkList(mosjMonitoringDataDetails, "ExecutiveInstitutions", cms, true, null);
            //String executiveInstitutionsList = getLinkListHtml(parameterExecutiveInstitutions, cms);
            if (!executiveInstitutionsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_EXECUTIVE_INSTITUTION, executiveInstitutionsList, true));
            }
            String contactPersonsList = createLinkList(mosjMonitoringDataDetails, "ContactPersons", cms, true, null);
            //String contactPersonsList = getLinkListHtml(parameterContactPersons, cms);
            if (!contactPersonsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_CONTACT_PERSON, contactPersonsList, true));
            }
            detailsHtml = detailsHtmlBuilder.toString();

            if (!detailsHtml.trim().isEmpty()) { // Anything in the list?
                detailsHtml = "<dl class=\"parameter-standard-meta\">" + detailsHtml + "</dl>";
            }

            detailsHtmlBuilder = new StringBuilder(512);

            if (CmsAgent.elementExists(parameterMethod)) {
                    detailsHtmlBuilder.append("<h4>" + LABEL_METHOD + "</h4>");
                    detailsHtmlBuilder.append(parameterMethod);
            }

            if (CmsAgent.elementExists(parameterQuality)) {
                    detailsHtmlBuilder.append("<h4>" + LABEL_QUALITY + "</h4>");
                    detailsHtmlBuilder.append(parameterQuality);
            }

            if (CmsAgent.elementExists(parameterOtherMetadata)) {
                    detailsHtmlBuilder.append("<h4>" + LABEL_OTHER_METADATA + "</h4>");
                    detailsHtmlBuilder.append(parameterOtherMetadata);
            }

            if (CmsAgent.elementExists(parameterReferenceLevel)) {
                    detailsHtmlBuilder.append("<h4>" + LABEL_REFERENCE_LEVEL + "</h4>");
                    detailsHtmlBuilder.append(parameterReferenceLevel);
            }

            // Print the details, if any
            detailsHtml += detailsHtmlBuilder.toString().trim();
            if (!detailsHtml.isEmpty()) {
                %>
                <div class="toggleable collapsed parameter-details-wrapper">
                    <a href="#<%= parameterDetailsSectionId %>" class="toggletrigger"><i class="icon-info-circled-1"></i> <%= LABEL_DETAILS %></a>
                    <div class="toggletarget tone-down" id="<%= parameterDetailsSectionId %>">
                        <%= detailsHtml %>
                    </div>
                </div><!-- .parameter-details-wrapper -->
                <%
            }
        } // if (details)
        
        %>
        </div><!-- .toggletarget.parameter-group-content -->
        </section><!-- .toggleable.open.parameter-wrapper.parameter-group -->
        <%
    } // while (monitoring data)
    %>
    </section>
	
	
    
    <%
    //
    // Dedicated paragraphs
    //    
    
    // The section (or content container) names and default titles
    Map<String, String> sections = new LinkedHashMap<String, String>();
    sections.put("StatusAndTrend", LABEL_STATUS_TRENDS);
    sections.put("CausalFactors", LABEL_CAUSAL_FACTORS);
    sections.put("Consequences", LABEL_CONSEQUENCES);
    sections.put("About", LABEL_ABOUT);
    
    boolean openAboutSection = false;
    String pTitle = null; // Holds any title override
    I_CmsXmlContentContainer dedicatedParagraph = null;
    
    for (String sectionName : sections.keySet()) {
        dedicatedParagraph = cms.contentloop(structuredContent, sectionName); 
        if (dedicatedParagraph.hasMoreResources()) {
            pTitle = cms.contentshow(dedicatedParagraph, "Title");
            if (!CmsAgent.elementExists(pTitle)) {
                pTitle = sections.get(sectionName);
            }
            if (sectionName.equals("About")) {
                out.println("<section class=\"paragraph clearfix\">");
                openAboutSection = true;
                cms.getRequest().setAttribute("useOuterWrapper", "false");
            }
            cms.getRequest().setAttribute("paragraphTitle", pTitle);
            cms.getRequest().setAttribute("paragraphElementName", sectionName);
            cms.include(PARAGRAPH_HANDLER);
        }
    }    
    cms.getRequest().removeAttribute("paragraphTitle");
    cms.getRequest().removeAttribute("paragraphElementName");
    
    //
    // Details 
    // (This is a part of the "About" section, which may already be open)
    //
    if (!openAboutSection) {
    %>
    <section class="paragraph clearfix">
        <h2><%= LABEL_ABOUT %></h2>
    <%
    }
    //
    // Places: This is printed only if there is content
    //
    I_CmsXmlContentContainer placesContainer = cms.contentloop(structuredContent, "Places");
    if (placesContainer.hasMoreResources()) {
        %>
        <h3><%= LABEL_PLACES %></h3>
        <%
        String placesText = cms.contentshow(placesContainer, "Text");
        String placesLinks = createLinkList(placesContainer, "Items", cms, false, null);
        if (CmsAgent.elementExists(placesText)) {
            out.println(placesText);
        }
        if (!placesLinks.isEmpty()) {
            out.println(placesLinks);
        }
    }
    
    //
    // Related monitoring: ALWAYS included (typically stating "none" if empty)
    //
    String monitoringProgrammesList = "";
    String internationalAgreementsList = "";
    String voluntaryInternationalCooperationsList = "";
    String relatedMonitoring = "";
    String otherMonitoring = "";
    
    I_CmsXmlContentContainer relatedContainer = cms.contentloop(structuredContent, "RelatedMonitoring");
    if (relatedContainer.hasMoreResources()) {
        monitoringProgrammesList = createLinkList(relatedContainer, "MonitoringProgramme", cms, true, LABEL_RELATED_MONITORING_NONE);
        internationalAgreementsList = createLinkList(relatedContainer, "InternationalAgreements", cms, true, LABEL_RELATED_MONITORING_NONE);
        voluntaryInternationalCooperationsList = createLinkList(relatedContainer, "VoluntaryInternationalCooperation", cms, true, LABEL_RELATED_MONITORING_NONE);
        relatedMonitoring = createLinkList(relatedContainer, "RelatedStuff", cms, true, LABEL_RELATED_MONITORING_NONE);
        otherMonitoring = createLinkList(relatedContainer, "Other", cms, true, null);
    } else {
        // Absolutely no related stuff ...
        monitoringProgrammesList 
                = internationalAgreementsList 
                = voluntaryInternationalCooperationsList 
                = relatedMonitoring 
                = createLinkList(relatedContainer, "foo", cms, true, LABEL_RELATED_MONITORING_NONE);
    }
    %>
    <h3><%= LABEL_RELATED_MONITORING %></h3>
    <dl>
        <dt><%= LABEL_RELATED_MONITORING_PROGRAMME %></dt>
            <%= monitoringProgrammesList %>
        <dt><%= LABEL_RELATED_MONITORING_AGREEMENT %></dt>
            <%= internationalAgreementsList %>
        <dt><%= LABEL_RELATED_MONITORING_COOPERATION %></dt>
            <%= voluntaryInternationalCooperationsList %>
        <dt><%= LABEL_RELATED_MONITORING_RELATED %></dt>
            <%= relatedMonitoring %>
        <% if (!otherMonitoring.isEmpty()) { %>
        <dt><%= LABEL_RELATED_MONITORING_OTHER %></dt>
            <%= otherMonitoring %>
        <% } %>
    </dl>
    </section>
    
    <%
    // Links
    String linksHtml = getLinkListHtml(cms.contentloop(structuredContent, "Links"), cms);

    // References 
    String refsHtml = "";
    I_CmsXmlContentContainer referencesWrapperContainer = cms.contentloop(structuredContent, "References");
    if (referencesWrapperContainer.hasMoreResources()) {

        I_CmsXmlContentContainer referencesContainer = cms.contentloop(referencesWrapperContainer, "Reference");
        while (referencesContainer.hasMoreResources()) {

            String referenceId = cms.contentshow(referencesContainer, "ID");
            String referenceText = cms.contentshow(referencesContainer, "Text");

            if (CmsAgent.elementExists(referenceId)) {
                refsHtml += "<li>";
                try {
                    refsHtml += new PublicationService(new Locale("en")).getPublication(referenceId).toString();
                } catch (Exception e) {
                    refsHtml += "<a href=\"//data.npolar.no/publication/" + referenceId + "\">" + referenceId + "</a><!-- Error looking up this: " + e.getMessage() + " -->";
                }
                refsHtml += "</li>";
            }
            if (CmsAgent.elementExists(referenceText) ) {
                refsHtml += "<li>" + CmsAgent.stripParagraph(referenceText) + "</li>";
            }
        }
    }

    if ((linksHtml != null && !linksHtml.isEmpty()) || (refsHtml != null && !refsHtml.isEmpty())) {
        %>
        <!--<aside class="content-related reference paragraph tabbed">-->
        <aside class="content-related paragraph tabbed nopad">
            <h2 class="content-related-heading tabbed-heading"><%= LABEL_FURTHER_READING %></h2>
            <% if (linksHtml != null && !linksHtml.isEmpty()) { %>
            <div class="content-related-links tab" id="links">
                <a class="tab-link" href="#links"><h2 class="tab-name"><%= LABEL_LINKS %></h2></a>
                <div class="tab-content">
                    <%= linksHtml %>
                </div>
            </div>
            <% 
            } 
            if (refsHtml != null && !refsHtml.isEmpty()) {
            %>
            <div class="content-related-links tab" id="refs">
                <a class="tab-link" href="#refs"><h2 class="tab-name"><%= LABEL_REFERENCES %></h2></a>
                <div class="tab-content">
                    <ol class="reference-list"><%= refsHtml %></ol>
                </div>
            </div>
            <% 
            }
            %>
        </aside>
        <%
    }

    // Reference list
    cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-reflist.jsp");
}

cms.include(cms.getTemplate(), "foot");
%>