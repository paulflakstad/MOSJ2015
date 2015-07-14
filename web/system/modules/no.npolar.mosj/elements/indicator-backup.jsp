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
            no.npolar.data.api.mosj.*,
            no.npolar.data.api.MOSJService,
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
		while (linkList.hasMoreResources()) {
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
		}
	} catch (Exception e) {
		// Handle this?
	}
	return listHtml;
}

public String getDefinitionListItem(String title, String data)  {
    return "<dt>" + title + "</dt>\n<dd>" + data + "</dd>";
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
final String LABEL_STATUS_TRENDS = loc.equalsIgnoreCase("no") ? "Status / trend" : "Status / trend";
final String LABEL_CAUSAL_FACTORS = loc.equalsIgnoreCase("no") ? "Årsaker / bakgrunn" : "Causal factors / background";
final String LABEL_CONSEQUENCES = loc.equalsIgnoreCase("no") ? "Konsekvenser" : "Consequences";
final String LABEL_ABOUT = loc.equalsIgnoreCase("no") ? "Om overvåkingen" : "About the monitoring";

final String LABEL_MONITORED_TITLE = loc.equalsIgnoreCase("no") ? "Hva overvåkes?" : "What is being monitored?";
final String LABEL_DETAILS = loc.equalsIgnoreCase("no") ? "Detaljer" : "Details";

final String LABEL_METHOD = loc.equalsIgnoreCase("no") ? "Metode" : "Method";
final String LABEL_QUALITY = loc.equalsIgnoreCase("no") ? "Kvalitet" : "Quality";
final String LABEL_REFERENCE_LEVEL = loc.equalsIgnoreCase("no") ? "Referansenivå og tiltaksgrense" : "Reference level and inititive threshold";

final String LABEL_UPDATE_INTERVAL = loc.equalsIgnoreCase("no") ? "Oppdateringsintervall" : "Update interval";
final String LABEL_NEXT_UPDATE = loc.equalsIgnoreCase("no") ? "Neste oppdatering" : "Next update";
final String LABEL_AUTHORATIVE_INSTITUTION = loc.equalsIgnoreCase("no") ? "Oppdragsgivende institusjon" : "Authorative institution";
final String LABEL_EXECUTIVE_INSTITUTION = loc.equalsIgnoreCase("no") ? "Utførende institusjon" : "Executive institution";
final String LABEL_CONTACT_PERSON = loc.equalsIgnoreCase("no") ? "Kontaktpersoner" : "Contact persons";

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
    
    %>
    
    <section class="article-hero">
        <h1><%= title %></h1>
        <figure>
            <img src="<%= cms.link(imgUri) %>" alt="" />
            <figcaption><%= cms.property("Description", imgUri, "") %></figcaption>
        </figure>            
    </section>
        
    <section class="descr">
        <%= summary %>
    </section>
	
    <%
    // ==========
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
    I_CmsXmlContentContainer mosjParameters = cms.contentloop(structuredContent, "MOSJParameter");
	%>
	<section class="paragraph clearfix">
	<h2 id="parametere"><%= LABEL_MONITORED_TITLE %></h2>
	<%
    int loopCount = 0; // Parameter counter
    String detailsHtml = "";
    while (mosjParameters.hasMoreResources()) {
        loopCount++;
        if (loopCount == 1 // IF this is the first parameter
                || !detailsHtml.trim().isEmpty()) { // OR details were found in previous parameter (in which case the wrapper was closed)
            //out.println("<!-- loop count: " + loopCount + ", detailsHtml.trim().isEmpty(): " + detailsHtml.trim().isEmpty() + " -->");
            // THEN begin the wrapper
            %>
            <div class="toggleable open parameter-wrapper">
            <%
        }
        // Parameter ID
        String pid = cms.contentshow(mosjParameters, "ID");
        String pTitleOverride = cms.contentshow(mosjParameters, "TitleOverride");
        JSONObject customization = null;
        try {
            customization = new JSONObject("{}");

            // Parameter customization
            //ArrayList<String> pCustom = new ArrayList<String>();
            I_CmsXmlContentContainer customSettingsContainer = cms.contentloop(mosjParameters, "ParameterCustomization");
            while (customSettingsContainer.hasMoreResources()) {
                //pCustom.add(cms.contentshow(customSettingsContainer, "Name") + ": '" + cms.contentshow(customSettingsContainer, "Value"));
                customization.put(cms.contentshow(customSettingsContainer, "Name"), cms.contentshow(customSettingsContainer, "Value"));
            }

            // Time series customization
            //JSONArray individualCustomizations = new JSONArray();
            //HashMap<String, List<String>> tsCustomMap = new HashMap<String, List<String>>();
            I_CmsXmlContentContainer mosjTimeSeriesCustomizations = cms.contentloop(mosjParameters, "TimeSeriesCustomization");
            while (mosjTimeSeriesCustomizations.hasMoreResources()) {
                JSONObject seriesCustomization = new JSONObject("{ \"id\": \"" + cms.contentshow(mosjTimeSeriesCustomizations, "TimeSeriesID") + "\" }");


                //ArrayList<String> tsCustom = new ArrayList<String>();
                customSettingsContainer = cms.contentloop(mosjTimeSeriesCustomizations, "Setting");
                while (customSettingsContainer.hasMoreResources()) {
                    //tsCustom.add(cms.contentshow(customSettingsContainer, "Name") + ": '" + cms.contentshow(customSettingsContainer, "Value"));
                    seriesCustomization.put(cms.contentshow(customSettingsContainer, "Name"), cms.contentshow(customSettingsContainer, "Value"));
                }
                customization.append("series", seriesCustomization);
                //tsCustomMap.put(cms.contentshow(mosjTimeSeriesCustomizations, "TimeSeriesID"), tsCustom);

            }
            out.println("<!-- Customization json created:\n" + customization.toString() + "\n-->");
        } catch (Exception e) {
            out.println("<!-- ERROR creating customization json: " + e.getMessage());
        }
        
        
        ResourceBundle labels = ResourceBundle.getBundle(no.npolar.data.api.Labels.getBundleName(), locale);

        MOSJService service = new MOSJService(locale);

        try {
            MOSJParameter mp = service.getMOSJParameter(pid).setDisplayLocale(locale);
            %>
            <h3 class="toggletrigger"><a href="javascript:void(0)"><%= mp.getTitle(locale) %></a></h3>
            <div class="toggletarget">
            <%
            List<MOSJTimeSeries> tss = mp.getTimeSeries();
            if (tss != null && !tss.isEmpty()) {
                Iterator<MOSJTimeSeries> i = tss.iterator(); 
                while (i.hasNext()) {
                    MOSJTimeSeries ts = i.next();
                    out.println("<!-- \nTime series:" 
                            //+ "\n" + ts.getAsTable()
                            + " " + ts.getTitle(locale)
                            + " " + ts.getID() 
                            //+ " [[" + ts.getUnitVerbose(loc) + "]]"
                            //+ " [[" + APIUtil.listToString(ts.getDataPoints(loc), null, ", ") + "]]"
                            + "\n-->");
                            //+ APIUtil.getStringByLocale(ts.getAPIStructure().getJSONArray("titles"), "title", loc));
                            //+ ts.getAPIStructure().getJSONArray("titles").getJSONObject(0).getString("title"));
                }
            }

            //pl(mp.getAsTable());
            //pl("------------");
            String htmlWrapper = "param-" + loopCount;
            %>
            <div id="<%= htmlWrapper %>"></div>
            <script type="text/javascript">
            $(function () {
                $('#<%= htmlWrapper %>').highcharts(<%= mp.getHighchartsConfig(customization) %>);
            });
            </script>
            <%

            //pl("Collected " + tss.size() + " related timeseries.");
        } catch (Exception e) {            
            out.println("</div>");
            out.println("<!-- \nERROR rendering indicator: " + e.getMessage() + "\n-->");
        }
        
        
        //
        // Parameter details
        //
        StringBuilder detailsHtmlBuilder = new StringBuilder(512);
        detailsHtml = "";

        String parameterMethod = cms.contentshow(mosjParameters, "Method");
        String parameterQuality = cms.contentshow(mosjParameters, "Quality");
        String parameterReferenceLevel = cms.contentshow(mosjParameters, "ReferenceLevel");

        String parameterUpdateInterval = cms.contentshow(mosjParameters, "UpdateInterval");
        String parameterNextUpdate = cms.contentshow(mosjParameters, "NextUpdate");
        I_CmsXmlContentContainer parameterContactPersons = cms.contentloop(mosjParameters, "ContactPersons");
        I_CmsXmlContentContainer parameterAuthorativeInstitutions = cms.contentloop(mosjParameters, "AuthorativeInstitutions");
        I_CmsXmlContentContainer parameterExecutiveInstitutions = cms.contentloop(mosjParameters, "ExecutiveInstitutions");

        // List on top of the details
        if (CmsAgent.elementExists(parameterUpdateInterval)) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_UPDATE_INTERVAL, parameterUpdateInterval));
        }
        if (CmsAgent.elementExists(parameterNextUpdate)) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_NEXT_UPDATE, parameterNextUpdate));
        }
        String authorativeInstitutionsList = getLinkListHtml(parameterAuthorativeInstitutions, cms);
        if (!authorativeInstitutionsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_AUTHORATIVE_INSTITUTION, authorativeInstitutionsList));
        }
        String executiveInstitutionsList = getLinkListHtml(parameterExecutiveInstitutions, cms);
        if (!executiveInstitutionsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_EXECUTIVE_INSTITUTION, executiveInstitutionsList));
        }
        String contactPersonsList = getLinkListHtml(parameterContactPersons, cms);
        if (!contactPersonsList.isEmpty()) {
                detailsHtmlBuilder.append(getDefinitionListItem(LABEL_CONTACT_PERSON, contactPersonsList));
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

        if (CmsAgent.elementExists(parameterReferenceLevel)) {
                detailsHtmlBuilder.append("<h4>" + LABEL_REFERENCE_LEVEL + "</h4>");
                detailsHtmlBuilder.append(parameterReferenceLevel);
        }

        // Print the details, if any
        detailsHtml += detailsHtmlBuilder.toString().trim();
        if (!detailsHtml.isEmpty()) {
            %>
            <div class="toggleable collapsed">
                <a href="javascript:void(0)" class="toggletrigger"><%= LABEL_DETAILS %></a>
                <div class="toggletarget tone-down">
                    <%= detailsHtml %>
                </div>
            </div>
            <%
            // Close the parameter wrappers (because we've printed details
            %>
            </div>
            </div>
            <%
        }
    } // while (more parameters)
    
    //
    // Done looping parameters
    //
    
    // Make absolutely sure parameter wrappers are closed
    // (Triggered only if there are no details whatsoever on any parameters)
    if (detailsHtml.trim().isEmpty()) {
        out.println("</div>");
        out.println("</div>");
    }
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
    %>
    
    
    <%
    
    
}


// Include reference list
cms.include("/system/modules/no.npolar.common.pageelements/elements/cn-reflist.jsp");




cms.include(cms.getTemplate(), "foot");
%>