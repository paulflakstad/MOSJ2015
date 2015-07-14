<%-- 
    Document   : indicator
    Created on : Dec 10, 2014, 1:30:18 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute
--%><%@page import="org.opencms.jsp.*,
            org.opencms.file.*,
            org.opencms.main.*,
            org.opencms.xml.*,
            org.opencms.json.*,
            java.util.*,
            org.opencms.security.*,
            no.npolar.util.*,
            no.npolar.data.api.*,
            no.npolar.data.api.mosj.*,
            no.npolar.data.api.util.APIUtil" pageEncoding="utf-8" session="true"
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
                        linkItems += "<a href=\"" + linkUrl + "\">";
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
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();

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
final String LABEL_JSON_LINK = cms.labelUnicode("label.mosj.indicator.data-json");// loc.equalsIgnoreCase("no") ? "Maskinlesbart format (JSON)" : "Machine-readable format (JSON)";
final String LABEL_JSON_LINK_DESCR = cms.labelUnicode("label.mosj.indicator.data-json-descr");
final String LABEL_CSV_LINK = cms.labelUnicode("label.mosj.indicator.data-csv");// loc.equalsIgnoreCase("no") ? "Maskinlesbart format (JSON)" : "Machine-readable format (JSON)";
final String LABEL_CSV_LINK_DESCR = cms.labelUnicode("label.mosj.indicator.data-csv-descr");
final String LABEL_DETAILS = cms.labelUnicode("label.mosj.indicator.data-details");// loc.equalsIgnoreCase("no") ? "Detaljer om disse dataene" : "Details on this data";

final String LABEL_METHOD = cms.labelUnicode("label.mosj.indicator.data-method");// loc.equalsIgnoreCase("no") ? "Metode" : "Method";
final String LABEL_QUALITY = cms.labelUnicode("label.mosj.indicator.data-quality"); // loc.equalsIgnoreCase("no") ? "Kvalitet" : "Quality";
final String LABEL_OTHER_METADATA = cms.labelUnicode("label.mosj.indicator.data-other-metadata");// loc.equalsIgnoreCase("no") ? "Andre metadata" : "Other metadata";
final String LABEL_REFERENCE_LEVEL = cms.labelUnicode("label.mosj.indicator.data-reference-level");// loc.equalsIgnoreCase("no") ? "Referansenivå og tiltaksgrense" : "Reference level and inititive threshold";

final String LABEL_UPDATE_INTERVAL = cms.labelUnicode("label.mosj.indicator.data-update-interval");// loc.equalsIgnoreCase("no") ? "Oppdateringsintervall" : "Update interval";
final String LABEL_NEXT_UPDATE = cms.labelUnicode("label.mosj.indicator.data-next-update");// loc.equalsIgnoreCase("no") ? "Neste oppdatering" : "Next update";
final String LABEL_AUTHORATIVE_INSTITUTION = cms.labelUnicode("label.mosj.indicator.data-autorative-institution");// loc.equalsIgnoreCase("no") ? "Oppdragsgivende institusjon" : "Authorative institution";
final String LABEL_EXECUTIVE_INSTITUTION = cms.labelUnicode("label.mosj.indicator.data-executive-institution");// loc.equalsIgnoreCase("no") ? "Utførende institusjon" : "Executive institution";
final String LABEL_CONTACT_PERSON = cms.labelUnicode("label.mosj.indicator.data-contact-person");// loc.equalsIgnoreCase("no") ? "Kontaktpersoner" : "Contact persons";

final String LABEL_FURTHER_READING = cms.labelUnicode("label.mosj.indicator.further-reading");
final String LABEL_LINKS = cms.labelUnicode("label.mosj.indicator.links"); //loc.equalsIgnoreCase("no") ? "Lenker" : "Links";
final String LABEL_REFERENCES = cms.labelUnicode("label.mosj.indicator.publications");// loc.equalsIgnoreCase("no") ? "Publikasjoner" : "Publications";

final String LABEL_CHART_LOAD = cms.labelUnicode("label.mosj.indicator.chart-loading");//loc.equalsIgnoreCase("no") ? "Laster graf&nbsp;&hellip;" : "Loading chart&nbsp;&hellip;";
final String LABEL_CHART_ERROR = loc.equalsIgnoreCase("no") ? 
                                    "Kan ikke vise grafen.</p><p class=\"placeholder-element-text-extra\">Prøv å laste inn siden på nytt. Du kan også <a href=\"/om/kontakt.html\">sende oss en feilmelding</a> hvis denne feilen vedvarer." 
                                    : 
                                    "Unable to display chart.</p><p class=\"placeholder-element-text-extra\">Try reloading the page. Please <a href=\"/about/contact.html\">report this error</a> should the problem persist.";

// Set the html document's title
String htmlDocTitle = cms.property("Title", requestFileUri, "");
request.setAttribute("title", htmlDocTitle);
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
    
    if (cms.elementExists(imgUri)) {
    %>
    
    
    <section class="article-hero">
        <div class="article-hero-content">
            <h1><%= title %></h1>
            <figure>
                <!--<img src="<%= cms.link(imgUri) %>" alt="" />-->
                <%= ImageUtil.getImage(cms, imgUri) %>
                <figcaption><%= cms.property("byline", imgUri, "") %></figcaption>
            </figure>            
        </div>
    </section>
    <%
    } else {
    %>
    <h1><%= title %></h1>
    <%
    }
    %>
    <section class="descr">
        <%= summary %>
    </section>
	
    <%
    I_CmsXmlContentContainer mosjMonitoringData = cms.contentloop(structuredContent, "MonitoringData");
    int monitoringDataLoopCount = 0;
    while (mosjMonitoringData.hasMoreResources()) {
        String titleOverride = cms.contentshow(mosjMonitoringData, "Title");
        
        if (monitoringDataLoopCount++ < 1) {
        %>
        <section class="paragraph clearfix">
        <h2 id="parametere"><%= LABEL_MONITORED_TITLE %></h2>
        <%
        }
        %>
        <div class="toggleable open parameter-wrapper">
        <%
        
        // 
        // Parameters
        // ==========
        //
        // The HTML output will be like this:
        //
        //  <parameter> <!-- wrapper
        //      <title> <-- normally the parameter title (auto-fetched), but should be overridden if there are multiple charts in one wrapper
        //      <chart> <-- could be one or more charts
        //      <details> <-- adding details will trigger the parameter wrapper to close
        //  </parameter> <-- wrapper closer - triggered either by existing details OR by the loop ending 
        //
        // Each parameter hooks into the API via an ID. The ID is used to fetch the 
        // time series data from the API, and this data is used to generate a chart.
        // 
        // It is possibly to apply custom settings to the chart, either for the 
        // entire thing or by time series.
        //
        // See also the backing classes in the no.npolar.data.api library.
        //
        I_CmsXmlContentContainer mosjParameters = cms.contentloop(mosjMonitoringData, "Parameter");
            
        int loopCount = 0; // Parameter counter
        while (mosjParameters.hasMoreResources()) {
            loopCount++;
            
            // Parameter ID
            String pid = cms.contentshow(mosjParameters, "ID");
            String parameterChartAltText = cms.contentshow(mosjParameters, "ChartAltText");
            String parameterChartCaption = cms.contentshow(mosjParameters, "ChartCaption");
            
            // Image present?
            String imageUri = cms.contentshow(mosjParameters, "Image");
            
                    
            if (CmsAgent.elementExists(imageUri)) {
                String imageHtml = null;
                if (CmsAgent.elementExists(parameterChartAltText)) {
                    imageHtml = ImageUtil.getImage(cms, imageUri, parameterChartAltText);
                } else {
                    imageHtml = ImageUtil.getImage(cms, imageUri);
                }
                %>
                <h3 class="toggletrigger"><a href="javascript:void(0)"><%= titleOverride %></a></h3>
                <div class="toggletarget"><!-- this div prevents layout from breaking down -->
                    <figure class="media">
                        <div class="hc-chart"><%= imageHtml %></div>
                        <% if (CmsAgent.elementExists(parameterChartCaption)) { %>
                        <figcaption class="caption"><%= parameterChartCaption %></figcaption>
                        <% } %>
                    </figure>
                <%
            } else {
            
            if (!pid.matches("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}")) {
                %>
                <div class="toggletarget"><!-- this div prevents layout from breaking down -->
                    <figure class="media">
                        <div class="hc-chart">
                            <div class="placeholder-element placeholder-element-chart">
                                <div class="placeholder-element-text">
                                    <p><%= LABEL_CHART_ERROR %></p>
                                </div>  
                            </div>
                        </div>
                    </figure>
                <%
                if (loggedInUser) {
                    %>
                    <script>
                        alert("CRITICAL ERROR: Parameter ID '<%= pid %>' is invalid.");
                    </script>
                    <%
                }
                
                continue;
            }
            
            // Chart customization
            JSONObject customization = null;
            try {
                customization = new JSONObject("{}");

                I_CmsXmlContentContainer mosjChartCustomization = cms.contentloop(mosjParameters, "ChartCustomization");
                if (mosjChartCustomization.hasMoreResources()) {
                    
                    // Chart-wide customization
                    I_CmsXmlContentContainer customSettingsContainer = cms.contentloop(mosjChartCustomization, "ParameterCustomization");
                    while (customSettingsContainer.hasMoreResources()) {
                        customization.put(cms.contentshow(customSettingsContainer, "Name"), cms.contentshow(customSettingsContainer, "Value"));
                    }

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
                    
                    out.println("<!-- Customization json created:\n" + customization.toString() + "\n-->");
                }
            } catch (Exception e) {
                out.println("<!-- ERROR creating customization json: " + e.getMessage());
            }


            ResourceBundle labels = ResourceBundle.getBundle(no.npolar.data.api.Labels.getBundleName(), locale);
            
            MOSJService service = new MOSJService(locale, cms.getRequest().isSecure());
            

            try {
                MOSJParameter mp = service.getMOSJParameter(pid).setDisplayLocale(locale);
                
                if (loopCount == 1) { // => Do this only on first iteration
                    String displayTitle = CmsAgent.elementExists(titleOverride) ? titleOverride : mp.getTitle(locale);
                    %>
                    <h3 class="toggletrigger"><a href="javascript:void(0)"><%= displayTitle %></a></h3>
                    <div class="toggletarget">
                    <%
                }
                
                List<TimeSeries> tss = mp.getTimeSeries();
                if (tss != null && !tss.isEmpty()) {
                    out.println("\n<!-- \nChart for parameter " + mp.getURL(service) + "\nTime series in this chart:");
                    Iterator<TimeSeries> i = tss.iterator(); 
                    while (i.hasNext()) {
                        TimeSeries ts = i.next();
                        out.println("\n\t\t" + ts.getTitle(locale) + " " + ts.getURL(service) + " - " + service.getServiceBaseURL() + "timeseries/" + ts.getId());
                    }
                    out.println("\n-->");
                }
                String chartWrapper = "param-" + pid;// + loopCount;
                %>
                <figure class="media">
                    <div id="<%= chartWrapper %>" class="hc-chart">
                        <div class="placeholder-element placeholder-element-chart">
                            <div class="placeholder-element-text">
                                <%= LABEL_CHART_LOAD %>
                            </div>  
                        </div>
                    </div>
                    <%
                    if (CmsAgent.elementExists(parameterChartAltText)) {
                    %>
                    <div class="element-alt-text"><%= parameterChartAltText %></div>
                    <%
                    }
                    if (CmsAgent.elementExists(parameterChartCaption)) {
                    %>
                    <figcaption class="caption">
                        <%= parameterChartCaption %>
                    </figcaption>
                    <%
                    }
                    %>
                    
                </figure>
                <!-- -->
                <div class="toggleable collapsed parameter-data-table-wrapper">
                    <a href="javascript:void(0)" class="toggletrigger"><i class="icon-grid"></i> <%= LABEL_TABLE_FORMAT %></a>
                    <div class="toggletarget">
                        <p>
                            <a class="cta" href="<%= cms.link("/data-export?id=" + mp.getId() + "&amp;locale=" + loc) %>" data-tooltip="<%= LABEL_CSV_LINK_DESCR %>">
                                <i class="icon-download-alt"></i> <%= LABEL_CSV_LINK %>
                            </a> 
                            <a class="cta" href="<%= mp.getURL(service) %>" data-tooltip="<%= LABEL_JSON_LINK_DESCR %>">
                                <i class="icon-database"></i> <%= LABEL_JSON_LINK %>
                            </a>
                        </p>
                        <%
                        out.println(mp.getAsTable("responsive")); 
                        //out.println(mp.getAsTable().replace("parameter-data-table", "parameter-data-table responsive")); 
                        %>
                    </div>
                </div>
                <!-- -->
                <script type="text/javascript">
                $(function () {
                    try {
                        $('#<%= chartWrapper %>').highcharts(<%= mp.getChart(customization).getChartConfigurationString() %>);
                    } catch (err) {
                        $('#<%= chartWrapper %> > .placeholder-element').addClass('placeholder-element-error').find('.placeholder-element-text').html('<p><%= LABEL_CHART_ERROR %></p>');
                    }
                });
                </script>
                <%

                //pl("Collected " + tss.size() + " related timeseries.");
            } catch (Exception e) {            
                out.println("</div>");
                out.println("<!-- \nERROR rendering indicator: " + e.getMessage() + "\n-->");
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
                    <a href="javascript:void(0)" class="toggletrigger"><i class="icon-info-circled-1"></i> <%= LABEL_DETAILS %></a>
                    <div class="toggletarget tone-down">
                        <%= detailsHtml %>
                    </div>
                </div>
                <%

            }
        }
        
        // Close the outer wrappers
        %>
        </div>
        </div>
        <%
    } // while (monitoring data)
    %>
	</section>
	
	
    
    <%
    //
    // Dedicated paragraphs
    // ToDo: Optimize - not exactly DRY code here ...
    //
    //HashMap paragraphParams = new HashMap();
    //I_CmsXmlContentContainer structuredContent = cms.contentload("singleFile", requestFileUri, false);
    //I_CmsXmlContentContainer copyStructContent = cms.contentload("singleFile", requestFileUri, false);
    
    String pTitle = null; // Holds title override

    I_CmsXmlContentContainer dedicatedParagraph = cms.contentloop(structuredContent, "StatusAndTrend"); 
    if (dedicatedParagraph.hasMoreResources()) {
        pTitle = cms.contentshow(dedicatedParagraph, "Title");
        if (!CmsAgent.elementExists(pTitle))
            pTitle = LABEL_STATUS_TRENDS;
        request.setAttribute("paragraphTitle", pTitle);
        request.setAttribute("paragraphElementName", "StatusAndTrend");
        cms.include(PARAGRAPH_HANDLER);
    }
    
    dedicatedParagraph = cms.contentloop(structuredContent, "CausalFactors");
    if (dedicatedParagraph.hasMoreResources()) {
        pTitle = cms.contentshow(dedicatedParagraph, "Title");
        if (!CmsAgent.elementExists(pTitle))
            pTitle = LABEL_CAUSAL_FACTORS;
        request.setAttribute("paragraphTitle", pTitle);
        request.setAttribute("paragraphElementName", "CausalFactors");
        cms.include(PARAGRAPH_HANDLER);
    }
    
    dedicatedParagraph = cms.contentloop(structuredContent, "Consequences");
    if (dedicatedParagraph.hasMoreResources()) {
        pTitle = cms.contentshow(dedicatedParagraph, "Title");
        if (!CmsAgent.elementExists(pTitle))
            pTitle = LABEL_CONSEQUENCES;
        request.setAttribute("paragraphTitle", pTitle);
        request.setAttribute("paragraphElementName", "Consequences");
        cms.include(PARAGRAPH_HANDLER);
    }

    dedicatedParagraph = cms.contentloop(structuredContent, "About");
    if (dedicatedParagraph.hasMoreResources()) {
        pTitle = cms.contentshow(dedicatedParagraph, "Title");
        if (!CmsAgent.elementExists(pTitle))
            pTitle = LABEL_ABOUT;
        request.setAttribute("paragraphTitle", pTitle);
        request.setAttribute("paragraphElementName", "About");
        cms.include(PARAGRAPH_HANDLER);
    }
    
    request.removeAttribute("paragraphTitle");
    request.removeAttribute("paragraphElementName");
    
    //
    // Details 
    // (should ideally be printed at the end of the "about" section above, but for now use a separate paragraph)
    //
    %>
    <section class="paragraph clearfix">
    <%
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
    // Related monitoring - ALWAYS printed, even if there is no content (typically explicitly stating "none")
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
        
        %>
    <%
    
    
}







cms.include(cms.getTemplate(), "foot");
%>