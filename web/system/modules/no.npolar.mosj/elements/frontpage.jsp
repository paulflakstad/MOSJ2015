<%-- 
    Document   : frontpage
    Created on : May 5, 2015, 11:01:23 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
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
public String toJsArrayValues(String commaSeparated) {
    String s = "";
    if (commaSeparated != null && !commaSeparated.isEmpty()) {
        String[] a = commaSeparated.split(",");
        for (String word : a) {
            s += "'" + word.trim() + "', ";
        }
        if (s.length() > 2)
            s = s.substring(0, s.length()-2);
    }
    return s;
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
final String SERP                   = loc.equalsIgnoreCase("no") ? "/no/sok.html" : "/en/search.html";

// Localized labels
final String LABEL_SEARCH_INDICATORS = cms.labelUnicode("label.mosj.search-indicators");// Search indicators


cms.include(cms.getTemplate(), "head");

    
String title = cms.labelUnicode("label.mosj.global.sitename") + " – MOSJ";
//String imgUri = "/no/img/indikatorer/isbjornunga_NP045713.jpg";
String imgUri = loc.equalsIgnoreCase("no") ? 
        "/no/img/indikatorer/NP045713-isbjornunger-polar-bear-cubs-jon-aars.jpg" : 
        "/en/img/indikatorer/NP045713-isbjornunger-polar-bear-cubs-jon-aars.jpg";
String summary = "<p>" 
        + (loc.equalsIgnoreCase("no") 
            ? 
            ("Presentasjoner og tolkninger av overvåkingsdata fra Svalbard og Jan Mayen.</p>"
            + "<p><a class=\"cta more\" style=\"float:none; font-size:1rem; margin-top:2em;\" href=\"/no/om/\">Mer om MOSJ</a>")
            //cms.labelUnicode("label.mosj.global.sitename") + " (MOSJ) presenterer og tolker overvåkingsdata og gir råd til forvaltningen. <a href=\"/no/om/\">Mer om MOSJ&hellip;</a>"
            : 
            ("Presentations and interpretations of monitoring data from Svalbard and Jan Mayen.</p>"
            + "<p><a class=\"cta more\" style=\"float:none; font-size:1rem; margin-top:2em;\" href=\"/en/about/\">More about MOSJ</a>")
           //cms.labelUnicode("label.mosj.global.sitename") + " (MOSJ) provides presentations and interpretation of monitoring data, and acts as adviser to the authorities. <a href=\"/en/about/\">More about MOSJ&hellip;</a>"
        ) + "</p>";
    
    %>
    
    <section class="article-hero">
        <div class="article-hero-content">
            <h1 class="hidden"><%= title %></h1>
            <figure>
                <%= ImageUtil.getImage(cms, imgUri, null) %>
                <!--<img src="<%= cms.link(imgUri) %>" alt="" />-->
                <figcaption><%= cms.property("byline", imgUri, "") %></figcaption>
            </figure>
            
            <div class="frontpage-searchbox-wrap">
                <form method="get" action="<%= cms.link(SERP) %>" id="frontpage-search-form">
                    <div class="searchbox">
                        <input type="search" id="search-indicator-name" name="query" value="" class="query-input" placeholder="<%= cms.labelUnicode("label.mosj.global.search.placeholder") %>" />
                        <input type="hidden" id="search-indicator-uri" name="uri" value="" />
                        <input type="button" value="OK" onclick="submit()" class="search-button" />
                    </div>
                </form>
            </div>
        </div>
    </section>
        
    <section class="descr" style="text-align:center;">
        <%= summary %>
    </section>
    

<script type="text/javascript">
function onIndicatorSuggestionSelected(event, suggestItem) {
    try { 
        var targetPageUriElement = document.getElementById('search-indicator-uri');
        targetPageUriElement.setAttribute('value', suggestItem['item']['uri']);
        document.activeElement.blur();
        $('#search-indicator-name').blur();		
        $('body').append('<div class="hang-on" style="position:fixed; left:0; right:0; top:0; bottom:0; width:100%; height:100%; background-color:rgba(0,0,0,0.8); z-index:9999;"><div class="loader" style="margin:20% auto;"></div></div>');
        $('#frontpage-search-form').submit();
    } catch (err) {
        console.log('ERROR: Select handler failed miserably ' + err);
    }
}
// Autocomplete config
var myConf = {
	uri:'/<%= loc %>/indicators-feed'
	//uri:'http://api.npolar.no/person/?fields=last_name,first_name,email,jobtitle.no,links&format=json&limit=50&facets=false&variant=array'
	//,results:'%(feed.entries)'
	,extract:'%(title)'
        ,events: { select:'onIndicatorSuggestionSelected' }
	//,pname_query:'q'
	//,pname_callback:'callback'
	,tpl_suggestion:'<a>%(title)</a>'
	//,tpl_suggestion:'<a>%(first_name) %(last_name)<br><em>%(jobtitle.no) - %(links:href[rel=profile])</em></a>'
	//,tpl_suggestion:'<a>%(first_name) %(last_name)<br><em>%(jobtitle.no) - %(links:href)</em></a>'
	//,tpl_suggestion:'<a>%(first_name) %(last_name)<br><em>%(jobtitle.no) - %(links)</em></a>'
	//,tpl_info:'<p><strong>%(first_name) %(last_name)</strong><br><em>%(jobtitle.no)</em></p>'
	,letters:3
	//,locale:'no'
};

$(document).ready(function() {
    if (!nonResIE()) {
        $('head').append('<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/themes/smoothness/jquery-ui.min.css" type="text/css" />');
        $.getScript('//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.js', function() {
            // underscore.js is not needed here (no complex selectors in the configuration)
            //$.getScript('<%= cms.link("/system/modules/no.npolar.opencms.widgets/resources/js/underscore.min.js") %>', function() {
                $.getScript('<%= cms.link("/system/modules/no.npolar.opencms.widgets/resources/js/string-suggest-widget-helpers.js") %>', function() {
                    $.getScript('<%= cms.link("/system/modules/no.npolar.opencms.widgets/resources/js/string-suggest-widget.js") %>', function() {
                        setupSuggest(JSON.stringify(myConf), document.getElementById('search-indicator-name'), '');
                    });
                });
            //});
        });
    }
    var phi = 0;
    function cyclePlaceholderText() {
        setTimeout(function() {
            setInterval(function() { 
                        var a = '<%= cms.labelUnicode("label.mosj.global.search.searchfor") %> ';
                        var ph = [<%= toJsArrayValues(cms.labelUnicode("label.mosj.global.search.placeholderwords")) %>];
                        document.getElementById('search-indicator-name').placeholder = a + ph[phi++];
                        if (phi === ph.length) {
                            phi = 0;
                        }
                    }, 1800);
        }, 4000);
    }
    cyclePlaceholderText();
});


//$('#config').html('<pre><code>' + escapeTags(JSON.stringify(myConf, undefined, 2)) + '</code></pre>');
//setupSuggest(JSON.stringify(myConf), document.getElementById('search-indicators'), '');
</script>
	
<%    
cms.include(cms.getTemplate(), "foot");
%>