<%-- 
    Document   : tsdata (= "time series data")
    Description: Outputs the data for a MOSJ time series identified by an "id" parameter.
                    The data is output as "[[<millis>,<value>],[<millis>,<value>],...]".
                    Multi-value series are not supported.
                    This page is an intermediate between a Highcharts chart and the NPDC 
                    API, providing API data transformed into a format that's directly 
                    chewable by Highcharts.
                    Typically employed only by Highcharts when a series contained in a 
                    chart is very long, to avoid a (potentially huge) negative impact on 
                    page load time.
    Created on : Nov 25, 2015, 4:26:33 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page pageEncoding="UTF-8"
            import="org.opencms.flex.CmsFlexController,
                    org.opencms.json.*,
                    java.util.*,
                    no.npolar.data.api.MOSJService,
                    no.npolar.data.api.TimeSeries,
                    no.npolar.data.api.util.APIUtil,
                    no.npolar.util.CmsAgent"
%><%!
public String toUTCDate(String s) {
    String[] parts = s.split("-");
    
    String year = parts[0];
    int month = Integer.parseInt(parts[1]);
    int date = Integer.parseInt(parts[2]);
    
    /*int year = Integer.parseInt(s.substring(0,4));
    int month = Integer.parseInt(s.substring(5,2));
    int date = Integer.parseInt(s.substring(8,2));*/
    return "" + year + "," + (month-1) + "," + date;
}
public String toZeroBasedMonth(String s) {
    String[] parts = s.split("-");
    
    String year = parts[0];
    int month = Integer.parseInt(parts[1]);
    int date = Integer.parseInt(parts[2]);
    
    /*int year = Integer.parseInt(s.substring(0,4));
    int month = Integer.parseInt(s.substring(5,2));
    int date = Integer.parseInt(s.substring(8,2));*/
    return "" + year + "-" + (month-1) + "-" + date;
}
synchronized public long toMillis(String s) {
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
    try {
        //return sdf.parse(toZeroBasedMonth(s)).getTime();
        return sdf.parse(s).getTime();
    } catch (Exception e) {
        return 0;
    }
}
%><%
    
CmsAgent cms = new CmsAgent(pageContext, request, response);
String tsId = cms.getRequest().getParameter("id");
String callback = cms.getRequest().getParameter("callback");
if (callback == null || callback.trim().isEmpty()) {
    callback = "?";
}

CmsFlexController controller = CmsFlexController.getController(request);
controller.getTopResponse().setContentType("application/javascript");
//controller.getTopResponse().setContentType("application/json");

out.print("" + callback + "(");

if (tsId == null) {
    out.print("{ 'error' : ' Time series ID is required, but was not provided.' }");
} else {

    MOSJService mosj = new MOSJService(cms.getRequestContext().getLocale(), true);
    String serviceBaseUrl = mosj.getTimeSeriesBaseURL();

    String params = "q="
                    + "&fields=" + TimeSeries.API_KEY_DATA_POINTS
                    + "&filter-id=" + tsId
                    + "&sort=" + TimeSeries.API_KEY_DATA_POINTS + "." + TimeSeries.API_KEY_POINT_WHEN
                    + "&format=json"
                    + "&facets=false"
                    + "&variant=array";


    String url = serviceBaseUrl + "?" + params; // E.g. https://api.npolar.no/indicator/timeseries/?q=&fields=data&filter-id=9e48e44f-58c0-47bb-957e-9a1f5c239781&format=json&facets=false&variant=array

    out.print("[");
    try {
        JSONArray rootArr = new JSONArray(APIUtil.httpResponseAsString(url));
        JSONArray dataArr = rootArr.getJSONObject(0).getJSONArray("data");
        
        long prevMillis = 0;
        for (int i = 0; i < dataArr.length(); i++) {
            if (i > 0)
                out.print(",");
            JSONObject dataObj = dataArr.getJSONObject(i);
            String val = dataObj.getString(TimeSeries.API_KEY_POINT_VAL);
            String date = dataObj.getString(TimeSeries.API_KEY_POINT_WHEN);
            long millis = toMillis(date);
            out.print("["+millis+","+val+"]");
            //out.print("["+millis+","+date+","+val+"]");
            //if (millis < prevMillis)
            //    throw new IllegalArgumentException("Not sorted!");
            //prevMillis = millis;
            //out.print("[Date.UTC("+toUTCDate(date)+"),"+val+"]");
        }

    } catch (Exception e) {
        out.print("{ 'error' : '" + e.getMessage() + "' }");
    } finally {
        out.print("]");
    }
}
out.println(");");
%>