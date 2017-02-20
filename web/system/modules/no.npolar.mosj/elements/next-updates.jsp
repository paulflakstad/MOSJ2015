<%-- 
    Document   : next-updates
    Created on : Aug 29, 2016, 1:36:04 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="org.opencms.jsp.CmsJspActionElement"%>
<%@page import="org.opencms.xml.content.CmsXmlContentFactory"%>
<%@page import="org.opencms.xml.content.CmsXmlContent"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="org.opencms.file.*"%>
<%@page import="java.util.*"%>
<%@page import="java.util.regex.Pattern" %>
<%@page import="org.opencms.main.*"%>
<%@page import="org.apache.commons.logging.Log"%>
<%@page contentType="text/html" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>

<%! 
    /** The required format for the "next scheduled update" info, for example: "December 2016". */
    public static final String PATTERN_SCHEDULED_UPDATE_TIME = "MMMM yyyy";
    
    /** The name of the property used to hold the "next scheduled update" info, as a localized string that fits {@link #PATTERN_SCHEDULED_UPDATE_TIME}. */
    public static final String PROPERTY_NEXT_SCHEDULED_UPDATE = "next-scheduled-update";

    /** The parameter name for the month parameter. */
    public static final String PARAM_MONTH = "m";

    /** The parameter name for the year parameter. */
    public static final String PARAM_YEAR = "y";

    /** The parameter name for the folder parameter. */
    public static final String PARAM_FOLDER = "folder";

    /** The delimiter used when separating multiple values. */
    public static final String VAL_DELIM = "|";

    /** The locale/language used by this script. */
    public static final Locale LOCALE_SCRIPT = new Locale("en");

    /** The months of the year (Calendar doesn't provide these in natural order). */
    public static final String[] MONTHS = new String[] {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    };

    /**
     * Determines whether or not the given date occurs inside the given month.
     * 
     * @return <code>true</code> if the given date occurs inside the given month, <code>false</code> otherwise.
     */
    private boolean isInMonth(Date someDate, Calendar theMonth) {
        if (someDate == null) {
            return false;
        }

        Calendar c = new GregorianCalendar();
        c.setTime(someDate);
        
        return theMonth.get(Calendar.MONTH) == c.get(Calendar.MONTH) && theMonth.get(Calendar.YEAR) == c.get(Calendar.YEAR);
    }

    /**
     * Determines whether or not the given date occurs in the past.
     * 
     * @return <code>true</code> if the given date occurs in the past, <code>false</code> otherwise.
     */
    private boolean isInPast(Date someDate) {
        if (someDate == null)
            return false;
        
        Calendar now = new GregorianCalendar();

        Calendar then = new GregorianCalendar();
        then.setTime(someDate);
        then.set(Calendar.DATE, then.getActualMaximum(Calendar.DATE));

        return then.before(now);
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <title>MOSJ: Check for updates</title>
        <style>
            *, *:before, *:after {
                box-sizing: border-box;
            }
            html {
                background: #fafafa;
            }
            body {
                margin: 0 auto;
                max-width: 80em;
                background: #fff;
                padding: 2em;
            }
            form,
            .msg {
                display: block;
                padding: 2rem; 
                margin: 2rem; 
                background: linear-gradient(0deg, #eee, #e7e7e7);
            }
            label,
            input, 
            button,
            form .reset {
                padding: .25rem;
                display: inline-block;
            }
            button {
                background: #189815;
                border: none;
                border-radius: 5px;
                color: white;
            }
            button:hover {
                background: #43C540;
            }
            form .reset {
                margin-top: 1rem;
                float: right;
            }
            ul {
                font-family: monospace;
            }
            li {
                padding-top: .5em;
                padding-bottom: .5em;
            }
            li + li {
                border-top: 1px solid #eee;
            }
            li a {
                font-weight: bold;
                max-width: 30em;
                text-overflow: ellipsis;
                display: inline-block;
                white-space: nowrap;
                overflow: hidden;
            }
            .warn {
                background-color: orange;
                display: inline-block;
                color: #fff;
                font-weight: bold;
            }
            .warn--critical {
                background-color: #f00;
            }
            .msg {
                background: lightblue;
                color: #fff;
            }
            .msg--confirm {
                background: green;
                background: linear-gradient(#afa, #ada);
                color: #050;
            }
            .related{
                color: #999;
            }
            
        </style>
    </head>
    <body>

<%
    CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    CmsObject cmso = cms.getCmsObject();
    
    
        
    Calendar nowCal = new GregorianCalendar(); 
    final int DEFAULT_MONTH = nowCal.get(Calendar.MONTH);
    final int DEFAULT_YEAR = nowCal.get(Calendar.YEAR);
        
    String mStr = request.getParameter(PARAM_MONTH);
    if (mStr == null || mStr.isEmpty()) {
        mStr = Integer.toString(DEFAULT_MONTH);
    }
    String yStr = request.getParameter(PARAM_YEAR);
    if (yStr == null || yStr.isEmpty()) {
        yStr = Integer.toString(DEFAULT_YEAR);
    }    
    String fStr = request.getParameter(PARAM_FOLDER);
    if (fStr == null || fStr.isEmpty()) {
        fStr = "/";
    }
    
    Calendar checkCal = new GregorianCalendar();
    checkCal.set(Calendar.YEAR, Integer.valueOf(yStr));
    checkCal.set(Calendar.MONTH, Integer.valueOf(mStr));
    
    String monthInfo = checkCal.getDisplayName(Calendar.MONTH, Calendar.LONG, LOCALE_SCRIPT)
            + " " + checkCal.get(Calendar.YEAR);
    
    
    
    String all = "";
    String notify = "";
    
    
    
    out.println("<h1>Checking for updates in " + monthInfo + "&nbsp;&hellip;</h1>");
    %>
    <form action="<%= cms.link(cms.getRequestContext().getUri()) %>" method="get">
        Check for updates in 
            <select name="<%= PARAM_MONTH %>" >
            <%
            for (int monthVal = 0; monthVal < MONTHS.length; monthVal++) {
            %>
                <option value="<%= monthVal %>"<%= (monthVal == checkCal.get(Calendar.MONTH) ? " selected=\"selected\"" : "") %>><%= MONTHS[monthVal] %></option>
            <%
            }
            %>
            </select> 
            <input name="<%= PARAM_YEAR %>" type="number" value="<%= yStr %>" />
        <br>
        <label>Check folder <input name="<%= PARAM_FOLDER %>" type="text" value="<%= fStr %>" /></label>
        <br>
        <button type="submit">Re-run check</button>
        <br>
        <a class="reset" href="<%= cms.link(cms.getRequestContext().getUri()) %>">Reset form</a>
    </form>
    <%

    // First, get the type ID for mosj_indicator resources
    int indicatorTypeId = -1;
    try {
        indicatorTypeId = OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId();
    } catch (Exception e) {
        out.println("<p class=\"warn warn--critical\">Aborting scheduled job: Required resource type mosj_indicator is not installed.</p>");
        out.println("</body></html>");
        return;
    }

    // Continue only if we found a valid type ID
    if (indicatorTypeId > 0) {

        SimpleDateFormat df;
        String folder = fStr;

        try {
            // Get iterator for indicator files
            Iterator<CmsResource> iResources = cmso.readResources(
                    folder
                    ,CmsResourceFilter.ALL.addRequireType(indicatorTypeId)
                    ,true
            ).iterator();
            
            // Add stuff to this list once checked
            List<CmsResource> checked = new ArrayList<CmsResource>(100);

            // Set up the initial locale and date format, using the locale of 
            // the folder we're using as root for this check
            Locale locale = new Locale( cmso.readPropertyObject(fStr, CmsPropertyDefinition.PROPERTY_LOCALE, true).getValue("en") );
            df = new SimpleDateFormat(PATTERN_SCHEDULED_UPDATE_TIME, locale);

            CmsResource resource;
            while (iResources.hasNext()) {
                resource = iResources.next();
                if (checked.contains(resource)) {
                    continue;
                }
                
                String itemHeading = "";
                
                // We have processed all locales
                for (CmsResource sibling : cmso.readSiblings(resource, CmsResourceFilter.ALL.addRequireType(indicatorTypeId))) {
                    checked.add(sibling);
                    itemHeading += (itemHeading.isEmpty() ? "" : " / ") 
                            + "<a href=\"" + cms.link(cmso.getSitePath(sibling)) + "\">"
                            + cmso.readPropertyObject(sibling, "Title", false).getValue("<em>" + cmso.getSitePath(sibling) + "</em>")
                            + "</a>";
                }

                // Will be set to true during the current iteration if we get a 
                // match on the "next update"
                boolean notifyItem = false;
                
                // The start of the list item is shared by both the "notify" and
                // the "full" list
                String item = "<li>" + itemHeading;

                // Get the 0-n "next update" values. 
                // We create the string as if we were pulling it off a property 
                // mapping (of type mapto="propertyList:...")
                String nextUpdateValues = "";
                int numUpdateValues = 0;
                CmsXmlContent resourceDocument = CmsXmlContentFactory.unmarshal(cmso, cmso.readFile(resource));
                for (Locale contentLang : resourceDocument.getLocales()) {
                    
                    // Extra line break to separate languages visually
                    if (numUpdateValues > 1) {
                        item += "<br>";
                    }
                    numUpdateValues = 0;
                    
                    // Adjust the date format to fit the current content's 
                    // language
                    df = new SimpleDateFormat(
                            PATTERN_SCHEDULED_UPDATE_TIME
                            ,contentLang//locale
                    );
                    
                    // 10 is just a number >= the maxOccur attribute of the 
                    // "MonitoringData" element
                    for (int i = 0; i < 10; i++) {
                        try {
                            // Pull "next update" value, e.g. "December 2016"
                            String nextUpdateValue = 
                                    resourceDocument.getValue(
                                                    "MonitoringData["+(i+1)+"]" 
                                                            + "/Details[1]"
                                                            + "/NextUpdate[1]"
                                                    , contentLang
                                    ).getStringValue(cmso).trim();
                            
                            // Pull the title
                            String updatePertainsTo = "[NO TITLE SET]";
                            try {
                                updatePertainsTo = 
                                        resourceDocument.getValue(
                                                    "MonitoringData["+(i+1)+"]"
                                                    + "/Title[1]"
                                                , contentLang
                                            ).getStringValue(cmso).trim();
                            } catch (Exception e) {
                                // ignore
                            }
                            
                            nextUpdateValues += (nextUpdateValues.isEmpty() ? "" : VAL_DELIM) + nextUpdateValue;

                            item += "<br>";
                            
                            numUpdateValues++;

                            Date nextUpdate = null;
                            try {
                                nextUpdate = df.parse(nextUpdateValue);
                                // If "next update" occured sometime in the past, add a warning
                                item += (isInPast(nextUpdate) ? "<span class=\"warn warn--critical\">EXPIRED:</span> " : "");
                            } catch (Exception e) {
                                item += "<span class=\"warn\">BAD VALUE:</span> ";
                            }

                            item += //"<br>Found 'next update' in " + locale.getDisplayLanguage(LOCALE_SCRIPT) + ": " + 
                                    nextUpdateValue 
                                    + " <span class=\"related\">&ndash; " + updatePertainsTo + ""
                                    + " (" + contentLang.getDisplayLanguage(LOCALE_SCRIPT) + ")</span>";

                            if (isInMonth(nextUpdate, checkCal)) {
                                notifyItem = true;
                            }

                        } catch (NullPointerException npe) {
                            continue;
                        } catch (Exception e) {
                            item += "<br><span class=\"warn warn--critical\">ERROR:</span> " + e.getMessage();
                            continue;
                        }
                    }

                    if (nextUpdateValues.isEmpty()) {
                        // Case: No scheduled update info present
                        item += "<br><span class=\"warn\">NEXT UPDATE NOT SET</span>";
                    }
                }
                
                item += "</li>";

                if (notifyItem) {
                    notify += item;
                }

                all += item;
                
            }
        } catch (Exception e) {
                out.println("<p class=\"warn warn--critical\"A critical error occured during this check!<br>" + e.getMessage() + "</p>");
                out.println("</body></html>");
                return;
        }
        
        if (!notify.isEmpty()) {
            out.println("<h2>Scheduled for update in " + monthInfo + ":</h2>"
                        + "<ul>" + notify + "</ul>");
        } else {
            out.println("<p class=\"msg msg--confirm\"><em>Checked and found no pages scheduled for update in " + monthInfo + ".</em></p>");
        }
        
        out.println("<h2>Pages checked in this run:</h2><ul>" + all + "</ul>");
    }
%>
    </body>
</html>