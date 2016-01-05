<%-- 
    Document   : newsletter-signup-form
    Description: Outputs the newsletter signup form (+ some js).
    Created on : Dec 22, 2015, 4:29:38 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
		java.util.*,
                no.npolar.util.CmsAgent"
                session="true" 
                contentType="text/html" 
                pageEncoding="UTF-8"
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
//CmsObject cmso              = cms.getCmsObject();
//String requestFileUri       = cms.getRequestContext().getUri();
//String requestFolderUri     = cms.getRequestContext().getFolderUri();
//Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();

//final String URI_FORM = "/" + loc + "/newsletter-signup-form.html";

final String FORM_HEADING = loc.equalsIgnoreCase("no") ? "Ja takk, send meg nyhetsbrev" : "Yes, I'd like to get the newsletter";
final String LABEL_REQUIRED = loc.equalsIgnoreCase("no") ? "indikerer obligatorisk felt" : "indicates required field";
final String LABEL_EMAIL = loc.equalsIgnoreCase("no") ? "E-post" : "Email";
final String LABEL_FNAME = loc.equalsIgnoreCase("no") ? "Fornavn" : "First name";
final String LABEL_LNAME = loc.equalsIgnoreCase("no") ? "Etternavn" : "Last name";
final String LABEL_SEND = loc.equalsIgnoreCase("no") ? "Send inn påmelding" : "Subscribe";

%><!-- Begin MailChimp Signup Form -->
<div id="mc_embed_signup">
<form action="//mosj.us11.list-manage.com/subscribe/post?u=510b0df76a6e3e60369a056bc&amp;id=73b70ff72d" method="post" id="mc-embedded-subscribe-form" name="mc-embedded-subscribe-form" class="validate" target="_blank" novalidate>
    <div id="mc_embed_signup_scroll">
        <h2><%= FORM_HEADING %></h2>
        <div class="indicates-required"><span class="asterisk">*</span> <%= LABEL_REQUIRED %></div>
        <div class="mc-field-group">
            <label for="mce-EMAIL"><%= LABEL_EMAIL %> <span class="asterisk">*</span></label>
            <input type="email" value="" name="EMAIL" class="required email" id="mce-EMAIL">
        </div>
        <div class="mc-field-group">
            <label for="mce-FNAME"><%= LABEL_FNAME %> </label>
            <input type="text" value="" name="FNAME" class="" id="mce-FNAME">
        </div>
        <div class="mc-field-group">
            <label for="mce-LNAME"><%= LABEL_LNAME %> </label>
            <input type="text" value="" name="LNAME" class="" id="mce-LNAME">
        </div>
        <div id="mce-responses" class="clear">
            <div class="response" id="mce-error-response" style="display:none"></div>
            <div class="response" id="mce-success-response" style="display:none"></div>
        </div>    <!-- real people should not fill this in and expect good things - do not remove this or risk form bot signups-->
        <div style="position: absolute; left: -5000px;" aria-hidden="true"><input type="text" name="b_510b0df76a6e3e60369a056bc_73b70ff72d" tabindex="-1" value=""></div>
        <div class="clear"><input type="submit" value="<%= LABEL_SEND %>" name="subscribe" id="mc-embedded-subscribe" class="button"></div>                                                                                                                 
    </div>
</form>
</div>
<script type='text/javascript' src='//s3.amazonaws.com/downloads.mailchimp.com/js/mc-validate.js'></script>
<script type='text/javascript'>
(function($) {
    window.fnames = new Array();
    window.ftypes = new Array();
    fnames[0]='EMAIL';ftypes[0]='email';
    fnames[1]='FNAME';ftypes[1]='text';
    fnames[2]='LNAME';ftypes[2]='text'; 
    <% if (loc.equalsIgnoreCase("no")) { %>
    /*
    * Translated default messages for the $ validation plugin.
    * Locale: NO (Norwegian)
    */
    $.extend($.validator.messages, {
           required: "Dette feltet er obligatorisk.",
           maxlength: $.validator.format("Maksimalt {0} tegn."),
           minlength: $.validator.format("Minimum {0} tegn."),
           rangelength: $.validator.format("Angi minimum {0} og maksimum {1} tegn."),
           email: "Oppgi en gyldig e-postadresse.",
           url: "Angi en gyldig URL.",
           date: "Angi en gyldig dato.",
           dateISO: "Angi en gyldig dato (&ARING;&ARING;&ARING;&ARING;-MM-DD).",
           dateSE: "Angi en gyldig dato.",
           number: "Angi et gyldig nummer.",
           numberSE: "Angi et gyldig nummer.",
           digits: "Skriv kun tall.",
           equalTo: "Skriv samme verdi igjen.",
           range: $.validator.format("Angi en verdi mellom {0} og {1}."),
           max: $.validator.format("Angi en verdi som er mindre eller lik {0}."),
           min: $.validator.format("Angi en verdi som er st&oslash;rre eller lik {0}."),
           creditcard: "Angi et gyldig kredittkortnummer."
    });
    <% } %>
}(jQuery));
var $mcj = jQuery.noConflict(true);
// 
// custom code from here
//
var responseTriggerActivated = false;
var successReceived = false;
$('#mc-embedded-subscribe').click(function() {
    try {
        // Get the form and response wrappers
        var form = $(this).closest("form");
        var responseContainers = form.find("#mce-responses .response");
        
        // Are there errors in the form? (If so, MC will not submit anything.)
        var formErrors = false;
        form.find("div.mce_inline_error").each( function() {
            if ($(this).is(':visible')) {
                formErrors = true;
            }
        });
                
        if (!formErrors) {
            // Assume form will be submitted to the newsletter service.
            // Allow some time for the form's own js to finish before we proceed.
            setTimeout(function() { 
                // Set up visual user feedback (i.e. "processing")
                form.find(".mc-field-group").fadeTo(300, 0.3);
                form.find(".mc-field-group input").attr("disabled", "disabled");
                //$("#mc_embed_signup .mc-field-group").fadeTo(300, 0.3);
                //$("#mc_embed_signup .mc-field-group input").attr("disabled", "disabled");

                // Clear any already existing response messages
                responseContainers.html("").css({"display":"none"});
                //form.find("#mce-responses .response").html("").css({"display":"none"});
                //$("#mce-responses .response").each(function() {
                //    $(this).css({"display":"none"});
                //    $(this).html("");
                //});

                // Trigger event when a response is received from the newsletter service
                if (!responseTriggerActivated) {
                    setInterval( function () {
                        try {
                            responseContainers.each(function() {
                            //form.find("#mce-responses .response").each(function() {
                            //$("#mce-responses .response").each(function() {
                                if ( $(this).html().length ) {
                                    // Response present, was it in "success"?
                                    if ($(this).attr("id").match(/success/g)) {
                                        successReceived = true;
                                    }
                                    $(this).trigger("responseReceived");
                                }
                            });
                            responseTriggerActivated = true;
                       } catch (ignore) {}
                    }, 100);
                }

                // Add listener for "response received"
                responseContainers.bind("responseReceived", function() {
                //form.find("#mce-responses .response").bind("responseReceived", function() {
                //$("#mce-responses .response").bind("responseReceived", function() {
                    if (!successReceived) {
                        form.find(".mc-field-group").fadeTo(300, 1);
                        form.find(".mc-field-group input").removeAttr("disabled");
                        //$("#mc_embed_signup .mc-field-group").fadeTo(300, 1);
                        //$("#mc_embed_signup .mc-field-group input").removeAttr("disabled");
                    } else {
                        $(this).attr("disabled", "disabled");
                    }
                });
                //console.log("Hooked into MC form events.");
            }, 100);
        } else {
            //console.log("Aborting, MC form had errors.");
        }
    } catch(ignore) {
        //console.log("Error hooking into MC form events: " + ignore);
    }
});
</script>
<!--End mc_embed_signup-->