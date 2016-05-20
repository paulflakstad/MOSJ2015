<%-- 
    Document   : test
    Created on : May 12, 2016, 2:51:46 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
            import="java.util.*"
            import="no.npolar.data.api.*"
            import="no.npolar.data.api.mosj.*"
            import="org.opencms.json.*"
            import="org.opencms.jsp.*"
            import="org.opencms.util.*"
%><%
    CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
    String id = request.getParameter("id");
    if (id == null) {
        id = "";
    }
	
	String lang = request.getParameter("lang");
	if (lang == null || !lang.matches("(no|en)")) {
		lang = "no";
	}
%><!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Test parameter</title>
        <style type="text/css">
            html, body {
                background:#fff;
                margin:0;
                padding:0;
                font-family:Arial, sans-serif;
                line-height:1.5em;
            }
            body {
                padding:4em 1em;
                margin:0 auto;
                max-width:1200px;
            }
            h1, form {
                text-align:center;
            }
            form {
                background:#f6eeee;
                display:block;
                padding:4em 0;
                margin:2em 0 4em 0;
            }
            input[type=text], 
            button {
                display:inline-block;
                font-size:1.2em;
                padding:0.5em;
                outline:none;
                box-sizing:border-box;
                margin-bottom:1em;
                /*border:1px solid #06e;*/
            }
            input[type=text] {
                width:40em;
            }
            pre {
                line-height:1.2em;
            }
            button {
                background-color:#08f;
                color:#fff;
                border:none;
            }
            
        </style>
    </head>
    <body>
        <h1>Test parameter</h1>
        <form action="<%= cms.link(cms.getRequestContext().getUri()) %>" method="get">
            <input type="text" name="id" value="<%= id %>" placeholder="Paste parameter ID here"><button type="submit">OK</button>
            <div>
                <label><input type="radio" name="lang" value="no"<%= lang.equals("no") ? " checked" : ""%>> Norsk </label>
                <label><input type="radio" name="lang" value="en"<%= lang.equals("en") ? " checked" : ""%>> English</label>
            </div>
        </form>
        <%
        if (id.trim().isEmpty()) {                
            return;
        } else {
            Locale loc = new Locale(lang);
            ResourceBundle labels = ResourceBundle.getBundle(no.npolar.data.api.Labels.getBundleName(), loc);
            MOSJService service = new MOSJService(loc, true);

            try {

                //String id = "2a4e646a-509f-5bf7-b478-333a722670f3";
                //String id = "a6e2c395-9e40-5703-af8b-be1ac1a456f6";
                //String id ="93a13173-f0ea-5514-9764-0d3f6f4b04dd";
                //String id = "44c4f706-5007-5c8e-b421-db1903c223a5"; // Kvikksølv (Hg) i egg fra polarlomvi
                //String id = "2a4e646a-509f-5bf7-b478-333a722670f3"; // Stabile organiske miljøgifter (POPs) i polartorsk (multiple time series)
                //String id = "214efdf2-ed37-5df9-b26c-277cb229a2df"; // Lufttemp. og nedbør
                //String id = "b10e3b9f-83eb-5d6d-be0c-b94f62e05d5f"; // Antall personer gått i land [...]
                //String id = "752751da-ee9c-5a07-8128-ede08300a9bb";
                //String id = "02f947ce-715b-58c0-a2bb-5a7998516611";
                //String id = "88c2dd73-3128-50f9-b36f-91d0cc397e14"; // Kondisjon hos voksne isbjørnhanner
                //String id = "29ac5f80-8dc8-5b1a-8adf-cac862178ba8"; // Cesium-137 i torsk
                //String id = "84d22a6e-87a2-5c6a-8b6d-ca3a92661c7e"; // PCB i luft
                //String id = "bf8a48fb-13b2-572e-8ea6-4e39039564b6"; // UV-doser
                //String id = "e4609ad3-c852-5489-9500-31b90ff4498d"; // Uttak: isbjørn
                //String id = "fdbafa00-844b-57db-8cc7-dbe27f2d41e0"; // Havisutbredelse i Barentshavet i april
                //String id = "1bfab4ea-109e-5cc4-bf2e-2d133d49b565"; //  Andel binner med unger av ulik alder
                //String id = "2a6b34f8-5cfa-547a-b07b-b7f08c9b928a"; // HCB, bHCH, DDE og BDE-47 i fjellrev
                //String id = "b0c97b7b-f3b5-5880-93c9-a3dbc4556215"; // Kronebreen/Holtedahlfonna mass balance
                //String id = "0482882f-1ac1-59ef-8aa4-356b4eef2325"; // HCH og HCB i isbjørn
                //String id = "c5bad5ca-7d64-5463-a999-8f902d71c858"; // Tykkelse av havis i Polhavet målt i Framstredet
                //String id = "88849d84-875c-5b64-85b2-eff41829a63e"; // Bakketemperatur i permafrost
                //String id = "7af14845-3f72-56a6-b047-1ca8aa193094"; // PCB-153, DDE og oksyklordan i fjellrev
                //String id = "e3d187c2-aabb-58e3-9600-547d0e78caf3"; // Antall dager med sjøis rundt viktige hiområder
                //String id = "8ebb3d9a-717c-53da-97cf-ec03dd2d6b34";
                //String id = "15457364-ce58-4688-89c6-a7ee6cb00ea0"; // Strandsøppel på Luftskipodden 100 m, per kategori - inverted grouping
                //String id = "75bfcb4b-ba3d-409b-84ff-edf65505c62b"; // Sum-PCB i innsjøsedimenter i Ellasjøen (industriprodukt) - literal time markers, e.g. "1980-1990"
                //String id = "13b2c155-9275-47b6-976e-1f63cd69fa83"; // Ferskvannsfluks i Framstredet
                //String id = request.getParameter("id"); // b3bfc8a2-577c-5508-9cda-5f90fabafbb6

                out.println("<p>Getting MOSJ parameter with ID " + id + " ...</p>");

                // Get the MOSJ parameter
                MOSJParameter mp = service.get(id);
                //mp.setDisplayLocale(loc);

                //mp.getTitle()

                // Create override object
                JSONObject overrides = new JSONObject();
                //overrides = new JSONObject("{\"enforceEqualSteps\":\"false\",\"step\":\"1\"}");
                //overrides = new JSONObject("{\"series\":[{\"id\":\"2d39469b-8e7f-5551-93a2-2fc6e0667333\",\"color\":\"#E52418\"},{\"id\":\"d29886df-e818-5bd3-99fb-20097259e0c1\",\"color\":\"#0277D5\"},{\"id\":\"79031ce1-de3b-556e-a04b-18f094d47aee\",\"color\":\"#000000 \"}]}");
                //overrides = new JSONObject("{\"series\":[{\"id\":\"c4d6d6d5-fcc3-465e-9151-7116525ddc79\",\"trendLine\":\"true\"},{\"id\":\"bdda8689-820d-4288-a948-e97f09b83964\",\"lineThickness\":\"0\"},{\"id\":\"b093b268-ae43-485a-a49d-3918ba1a8c0d\",\"lineThickness\":\"0\"},{\"id\":\"9e93e67d-e744-4217-9421-1e4181466db1\",\"trendLine\":\"true\",\"color\":\"#eee\"}]}");
                //overrides = new JSONObject("{\"series\":[{\"id\":\"c4d6d6d5-fcc3-465e-9151-7116525ddc79\",\"trendLine\":\"true\"},{\"id\":\"bdda8689-820d-4288-a948-e97f09b83964\",\"lineThickness\":\"0\"},{\"id\":\"b093b268-ae43-485a-a49d-3918ba1a8c0d\",\"lineThickness\":\"0\"},{\"id\":\"9e93e67d-e744-4217-9421-1e4181466db1\",\"trendLine\":\"true\"},{\"id\":\"9e93e67d-e744-4217-9421-1e4181466db1\",\"color\":\"#eee\"}]}");
                //overrides = new JSONObject("{\"series\":[" 
                //                                        + "{ \"id\":\"9e93e67d-e744-4217-9421-1e4181466db1\", \"trendLine\":\"true\" }" 
                                                        //+ "{ \"id\":\"9e93e67d-e744-4217-9421-1e4181466db1\", \"trendLine\":\"true\", \"color\":\"#eee\" }" 
                                                        //+ "{\"id\":\"4bef90cf-2d79-45fb-a9a7-64abda0002e0\", \"dots\":\"false\", \"trendLine\":\"true\"}" 
                                                        //+ ",{id:'d4487834-31b2-4838-8f76-59b15c81eacb', dots:'false', trendLine:'true'}" 
                                                        //+ ",{id:'077d780d-19de-4040-b474-9614a592301f', dots:'false', trendLine:'true'}" 
                                                        //+ ",{id:'b6563b5f-d2d7-49e5-9bfc-f5db8211b4be', dots:'false', trendLine:'true'}"
                //                                    + "]}");
                //overrides = new JSONObject("{ series: [{id:'a74c550f-25b3-526d-a5c2-92945db572c4', type:'bar'}] }");
                //overrides = new JSONObject("{ errorToggler: true, type: column, series: [{id:'a74c550f-25b3-526d-a5c2-92945db572c4', type:'bar'}] }");
                //overrides = new JSONObject("{ series: [{id:'94225197-ad05-5c19-9c9d-c1e8bfeaf1f9', type:'column', yAxis:'1'}, {id:'1af3f195-1c25-5130-b1f5-3b9ce1ffcbd2', yAxis:'0'}, {id:'14bf4a87-8966-52a2-a86e-7695bda9deb9', yAxis:'0'}] }");
                //overrides = new JSONObject("{ invertGrouping:true, \"series\":[{\"id\":\"2012\",\"color\":\"2\"},{\"id\":\"2013\",\"color\":\"3\"},{\"id\":\"2015\",\"color\":\"5\"}]}");

                out.println("<h2>Parameter: " + mp.getTitle(loc) + "</h2><p>" + "<a href=\"" + mp.getURL(service) + "\">" + mp.getURL(service) + "</a></p>");

                List<TimeSeries> tss = mp.getTimeSeries();
                if (tss != null && !tss.isEmpty()) {
                    out.println("<h4>Related time series:</h4>");
                    out.println("<table><tr><th>Name</th><th>Value label</th><th>URL</th></tr>");
                    Iterator<TimeSeries> i = tss.iterator(); 
                    while (i.hasNext()) {
                        TimeSeries ts = i.next();
                        out.println("<tr>"
                                //+ "\n" + ts.getAsTable()
                                //+ "    " + ts.getTitle(loc)
                                + "<td>" + ts.getLabel() + (ts.isErrorBarSeries() ? " (error bar series)" : "") + "</td>"
                                + "<td>[" + ts.getUnit().getLongForm() + "]</td>"
                                + "<td><a href=\"" + ts.getURL(service) + "\">" + ts.getURL(service) + "</a></td>"
                                //+ " " + ts.getId()
                                //+ " [[" + ts.getUnitVerbose(loc) + "]]"
                                //+ " [[" + APIUtil.listToString(ts.getDataPoints(loc), null, ", ") + "]]"
                                //+ APIUtil.getStringByLocale(ts.getAPIStructure().getJSONArray("titles"), "title", loc)
                                //+ ts.getAPIStructure().getJSONArray("titles").getJSONObject(0).getString("title")
								+ "</tr>"
                                );

                        //pl(ts.getAPIStructure().getJSONArray("titles").toString(4));
                        //break;
                    }
                    out.println("</table>");
                }

                HighchartsChart chart = mp.getChart(overrides);
                //pl("\n############\nTable format:\n" + chart.getHtmlTable());

                out.println("<h4>Table format:</h4>" + mp.getAsTable("responsive"));
                out.println("<h4>CSV format:</h4><blockquote><pre>" + mp.getAsCSV() + "</pre></blockquote>");
                out.println("<h4>Highcharts:</h4><blockquote><pre>" + chart.getChartConfigurationString().replace("<", "&lt;").replace(">", "&gt;") + "</pre></blockquote>");

                //pl(mp.getHighchartsConfig(overrides));

                //pl("Collected " + tss.size() + " related timeseries.");
            } catch (Exception e) {
                out.println("<h4>Error: " + e.getMessage() + "</h4>");
                out.println("<pre>");
                e.printStackTrace(response.getWriter());
                out.println("</pre>");
            }
        }
        %>
    </body>
</html>
