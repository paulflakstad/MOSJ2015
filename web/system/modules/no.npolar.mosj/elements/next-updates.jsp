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
<%@page import="org.opencms.main.*"%>
<%@page import="org.apache.commons.logging.Log"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%!
    /** The logger for this class. */
    //private static final Log LOG = CmsLog.getLog(NotificationResources.class);

    /** The CmsObject (passed to this class from the scheduled job instance). */
    //private CmsObject cmso;

    /** The resources which are eligible for notification. */
    private List<CmsResource> resourcesToNotifyAbout;
    
    /** The required format for the "next scheduled update" info, for example: "December 2016". */
    public static final String PATTERN_SCHEDULED_UPDATE_TIME = "MMMM yyyy";
    
    /** The name of the property used to hold the "next scheduled update" info, as a localized string that fits {@link #PATTERN_SCHEDULED_UPDATE_TIME}. */
    public static final String PROPERTY_NEXT_SCHEDULED_UPDATE = "next-scheduled-update";

    
    
    /**
     * Checks if the given date is next month.
     * 
     * @param someDate The date in question.
     * @return true if the given date is next month, false otherwise.
     */
    private boolean isNextMonth(Date someDate) {
        return isNMonthsFromNow(someDate, 1);
    }

    private boolean isNMonthsFromNow(Date someDate, int monthsFromNow) {
        if (someDate == null)
            return false;
        
        Calendar now = new GregorianCalendar();
        now.set(Calendar.DATE, 1);
        /*if (monthsFromNow == 0) {
            return false;
        } else {
            if (now.getTime().after(someDate)) {
                return false;
        }*/
        now.add(Calendar.MONTH, monthsFromNow);

        Calendar then = new GregorianCalendar();
        then.setTime(someDate);
        return then.get(Calendar.MONTH) == now.get(Calendar.MONTH) && then.get(Calendar.YEAR) == now.get(Calendar.YEAR);
    }

    /**
     * Sends a notification email to the responsible, that is, the address(es) 
     * defined as {@link NotifyUpcomingUpdateJob#PARAMETER_SEND_TO} in the 
     * parameters section of the scheduled job.
     * 
     * @param parameters The parameters, passed from the scheduled job's configuration.
     * @return A string indicating the result of this method.
     * @see NotifyUpcomingUpdateJob#PARAMETER_SEND_TO
     */
    public String getUpdatesList(CmsObject cmso, List<CmsResource> resourcesToNotifyAbout) {
        if (!resourcesToNotifyAbout.isEmpty()) {
            String body = "";
            try {
                body += "<p>These MOSJ pages are scheduled for update:</p>"
                            + "<ul>";
                for (CmsResource r : resourcesToNotifyAbout) {
                    body += "<li>" 
                                + "<a href=\"" + cmso.getSitePath(r) + "\">"
                                    + cmso.readPropertyObject(r, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue("<em>" + cmso.getSitePath(r) + "</em>") 
                                + "</a>"
                                + "<br>";
                    body += "   " + OpenCms.getLinkManager().getOnlineLink(cmso, cmso.getSitePath(r)) + "</li>";
                }
                body += "</ul>";
                
            } catch (Exception e) {
                String msg = "An error occured while attempting to send notification about upcoming updates.";
                /*if (LOG.isErrorEnabled()) {
                    LOG.error(msg, e);
                }*/
                return msg;
            }
            return body;
        }
        return "Checked and found no pages with updates coming up in the specified period.";
    }
%><%
    CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    CmsObject cmso = cms.getCmsObject();
    
    String mStr = request.getParameter("m");
    if (mStr == null) {
        out.println("Missing parameter <code>m</code>, defining the number of months to look ahead. Set it to e.g. <a href=\"?m=1\">?m=1</a> to check for updates next month.");
        return;
    }
    int monthsAhead = Integer.parseInt(mStr); 
    String all = "";
    
    out.println("<h1>Checking for updates " + monthsAhead + " months ahead</h1>");
    
    
    /**
     * Collects <code>mosj_indicator</code> resources that are scheduled for 
     * update next month.
     */

    // First, get the type ID for mosj_indicator resources
    int indicatorTypeId = -1;
    try {
        indicatorTypeId = OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId();
    } catch (Exception e) {
        /*if (LOG.isErrorEnabled()) {
            LOG.error("Aborting scheduled job: Required resource type mosj_indicator is not installed.");
        }*/
    }

    // Continue only if we found a valid type ID
    if (indicatorTypeId > 0) {

        SimpleDateFormat df;
        List<CmsResource> resourcesToNotifyAbout = new ArrayList<CmsResource>();
        String folder = cms.getRequestContext().getFolderUri();

        try {
            // Get iterator for indicator files
            Iterator<CmsResource> iResources = cmso.readResources(
                    folder
                    ,CmsResourceFilter.ALL.addRequireType(indicatorTypeId)
                    ,true
            ).iterator();

            // Set up the initial locale and date format
            Locale locale = cmso.getRequestContext().getLocale();
            df = new SimpleDateFormat(PATTERN_SCHEDULED_UPDATE_TIME, locale);

            CmsResource resource;
            while (iResources.hasNext()) {
                resource = iResources.next();
                
                all += "<li>" 
                        + "<a href=\"" + cms.link(cmso.getSitePath(resource)) + "\">"
                        + cmso.readPropertyObject(resource, "Title", false).getValue("<em>" + cmso.getSitePath(resource) + "</em>")
                        + "</a>";

                // Start new: Get 0-n next update values, that is, just like 
                // pulling the value off a property mapped against using 
                // mapto="propertyList:..."
                String nextUpdateValues = "";
                CmsXmlContent resourceDocument = CmsXmlContentFactory.unmarshal(cmso, cmso.readFile(resource));
                for (int i = 0; i < 10; i++) {
                    try {
                        nextUpdateValues += (nextUpdateValues.isEmpty() ? "" : "|") 
                                + resourceDocument.getValue("MonitoringData[" + (i+1) + "]/Details[1]/NextUpdate[1]", locale).getStringValue(cmso).trim();
                    } catch (Exception e) {
                        break;
                    }
                }
                // End new

                if (nextUpdateValues.isEmpty()) {
                    // No scheduled update, skip this one
                    continue;
                }

                // Scheduled update info was present -> Parse it to see if 
                // it is next month. (Should be e.g. "December 2016".)

                // Adjust the date format to fit the current resource's 
                // configured locale (if necessary)
                String resourceLocaleStr = cmso.readPropertyObject(resource, CmsPropertyDefinition.PROPERTY_LOCALE, true).getValue("en");
                if (!resourceLocaleStr.equalsIgnoreCase(locale.getLanguage())) {
                    locale = new Locale(resourceLocaleStr);
                    df = new SimpleDateFormat(
                            PATTERN_SCHEDULED_UPDATE_TIME
                            , locale
                    );
                }

                Date nextUpdate;

                // Begin new
                String[] nextUpdateValuesArr = nextUpdateValues.split("\\|");
                for (String nextUpdateValue : nextUpdateValuesArr) {
                    try {
                        nextUpdate = df.parse(nextUpdateValue);
                        all += "<br>" + nextUpdateValue;
                    } catch (Exception e) {
                        /*if (LOG.isErrorEnabled()) {
                            LOG.error("Parsing '" + nextUpdateValue + "' as a month failed"
                                    //+ " on property '" + PROPERTY_NEXT_SCHEDULED_UPDATE + "'"
                                    + " for resource '" + cmso.getSitePath(resource) + "'"
                                    + ".");
                        }*/
                        all += "<br><strong style=\"color:red;\">ERROR</strong>: " + nextUpdateValue;
                        continue;
                    }

                    if (isNMonthsFromNow(nextUpdate, monthsAhead)) {
                        resourcesToNotifyAbout.add(resource);
                        break;
                    }
                }
                // End new
                all += "</li>";
            }
        } catch (Exception e) {
            /*if (LOG.isErrorEnabled()) {
                LOG.error("A critical error occured during a scheduled job.", e);
            }*/
        }
        
        out.println(getUpdatesList(cmso, resourcesToNotifyAbout));
        
        out.println("<h2>Full list</h2><ul style=\"font-family:monospace;\">" + all + "</ul>");
    }
%>