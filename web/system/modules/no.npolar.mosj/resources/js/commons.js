/**
 * Common javascript funtions, used throughout the site.
 * Dependency: jQuery (must be loaded before this script)
 * Dependency: Highslide (must be loaded before this script)
 */

/*
 * jQuery hover delay plugin. 
 * http://ronency.github.io/hoverDelay/
 * https://github.com/ronency/hoverDelay
 * Function license: MIT.
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 ronency
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
$.fn.hoverDelay = function(options) {
    var defaultOptions = {
        delayIn: 300,
        delayOut: 300,
        handlerIn: function($element){},
        handlerOut: function($element){}
    };
    options = $.extend(defaultOptions, options);
    return this.each(function() {
        var timeoutIn, timeoutOut;
        var $element = $(this);
        $element.hover(
            function() {
                if (timeoutOut){
                    clearTimeout(timeoutOut);
                }
                timeoutIn = setTimeout(function(){options.handlerIn($element);}, options.delayIn);
            },
            function() {
                if (timeoutIn){
                    clearTimeout(timeoutIn);
                }
                timeoutOut = setTimeout(function(){options.handlerOut($element);}, options.delayOut);
            }
        );
    });
};
  
/**
 * Function for altering table rows by class insertion.
 */
function makeNiceTables() {
    // Get all tables on the page
    var tables = document.getElementsByTagName("table");

    //alert("Found " + tables.length + " tables on this page.");

    var table;
    // Loop over all tables
    for (var i = 0; i < tables.length; i++) {
        table = tables[i]; // Current table

        //alert("Processing table #" + i + "...");

        // Require a specific class name
        if (table.className === "odd-even-table") {
            //alert("This table was of required class.");
            var tableRows = table.getElementsByTagName("tr");

            // Check if the first row contains no th's
            if (tableRows[0].getElementsByTagName("th").length === 0) { 
                tableRows[0].className = "even";
            }

            //alert("Found " + tableRows.length + " table rows in this table.");
            for (j = 1; j < tableRows.length; j++) { // Start at index 1 (skip first row, which we've processed already)
                var tableRow = tableRows[j];
                if ((j+2) % 2 === 0) {
                    tableRow.className = "even";
                }
                else {
                    tableRow.className = "odd";
                }
            }
        } else {
            //alert("This table was not of required class.");
        }
    }
}

/**
 * Handle hash (fragment) change
 */
function highlightReference() {
    setTimeout(function() {
            if(document.location.hash) {
                var hash = document.location.hash.substring(1); // Get fragment (without the leading # character)
                try {
                    $(".highlightable").css("background-color", "transparent");
                    $("#" + hash + ".highlightable").css("background-color", "#feff9f");
                    //alert (hash);
                } catch (jsErr) {}
            }
            else {
                //alert("No hash");
            }
        },
        100
    );
}

/*
function highlightReference() {
	if(document.location.hash) {
		var hash = document.location.hash.substring(1); // Get fragment (without the leading # character)
		try {
			document.getElementsByClassName("highlightable")
			document.getElementById(hash).style.backgroundColor = "#eef6fc";
			//alert (hash);
		} catch (jsErr) {}
	}
}
*/
/*
if ("onhashchange" in window) { // event supported?
    window.onhashchange = function () {
        hashChanged(window.location.hash);
    }
}
else { // event not supported:
    var storedHash = window.location.hash;
    window.setInterval(function () {
        if (window.location.hash != storedHash) {
            storedHash = window.location.hash;
            hashChanged(storedHash);
        }
    }, 100);
}
*/

/**
 * Helper function for browser sniffing
 */
navigator.sayswho = (function() {
    var N = navigator.appName, ua = navigator.userAgent, tem;
    var M = ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i);
    tem = ua.match(/version\/([\.\d]+)/i);
    if (M && tem !== null) M[2] = tem[1];
    M = M ? [M[1], M[2]] : [N, navigator.appVersion, '-?'];

    return M;
})();

/**
 * Calculates the width of the browser's scrollbar
 */
function getScrollbarWidth() {
    // Create a small div with a large div inside (will trigger scrollbar)
    var div = $("<div style=\"width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;\"><div style=\"height:100px;\"></div></div>");
    // Append our div, do our calculation and then remove it
    $("body").append(div);
    var w1 = $("div", div).innerWidth();
    div.css("overflow-y", "scroll");
    var w2 = $("div", div).innerWidth();
    $(div).remove();
    return (w1 - w2);
}

/**
 * Returns true if the browser is IE8 (or an older IE version)
 */
function nonResIE() {
    if (navigator.sayswho[0].match('MSIE')) { 
        var version = navigator.sayswho[1];
        version = version.substring(0, version.indexOf('.'));
        //console.log('Version is: "' + version + '"');
        if (version.length > 1)
            return false;
        else if (version < '9')
            return true;
    }
    return false;
}

/**
 * Checks if an element, identified by the given ID, contains any real content.
 * @param id The ID that identifies the element to check
 * @return True if the element is non-existing or the element doesn't contain any real content, false if not
 */
function emptyOrNonExistingElement(id) {
    var el = document.getElementById(id); // Get the element
    if (!(el == null || el == undefined)) { // Check for non-exising element first
        var html = el.innerHTML; // Get the content inside the element
        if (html != null) {
            html = html.replace(/(\r\n|\n|\r)/gm, ''); // Remove any and all linebreaks
            html = html.replace(/^\s+|\s+$/g, ''); // Remove empty spaces at front and end
            if (html == '')
                return true; // The element didn't contain anything (except maybe whitespace and linebreaks)
            return false; // The element contained something
        }
    }
    return true; // The element didn't exist
}

function getVisibleWidth() {
    return $(window).width() + getScrollbarWidth();
}

function getSmallScreenBreakpoint() {
    return 800; // Viewport widths equal to or below this value are considered "small screens"
}

function isSmallScreen() {
    return getVisibleWidth() <= getSmallScreenBreakpoint();
}

function initToggleables() {
    $('.toggleable.collapsed > .toggletarget').slideUp(1); // Hide normally-closed ("collapsed") accordion content		
    $('.toggleable.collapsed > .toggletrigger').prepend('<em class="icon-down-open-big"></em> '); // Append arrow icon to "show accordion content" triggers
    $('.toggleable.open > .toggletrigger').prepend('<em class="icon-up-open-big"></em> '); // Append arrow icon to "hide accordion content" triggers
    $('.toggleable > .toggletrigger').click( function() {
        $(this).next('.toggletarget').slideToggle(500); // Slide up/down the next toggle target ...
        $(this).children('em').first().toggleClass('icon-up-open-big icon-down-open-big'); // ... and toggle the icon class, so the arrows change corresponding to the slide up/down
    });
}

function showOutlines() {
    try { 
        document.getElementById("_outlines").innerHTML="a:focus, input:focus, button:focus, select:focus { outline:thin dotted; outline:2px solid orange; }"; 
    } catch (err) { 
        return false; 
    }
    return true;
}
function hideOutlines() {
    try { 
        document.getElementById("_outlines").innerHTML="a, a:focus, input:focus, select:focus { outline:none !important; } /*a:focus { border:none !important; }*/"; 
    } catch (err) { 
        return false; 
    } 
    return true;
}

/**
 * @see http://support.addthis.com/customer/portal/articles/1293805-using-addthis-asynchronously#.UxSMJuIkAU8
 */
/*
function loadAddThis() {
    //var addthisScript = document.createElement('script');
    //addthisScript.setAttribute('src', 'http://s7.addthis.com/js/300/addthis_widget.js#domready=1');
    //addthisScript.setAttribute('type', 'text/javascript');
    //document.body.appendChild(addthisScript);

    // Add the profile ID (pubid)
    var addthis_config = addthis_config||{};
    addthis_config.pubid = 'ra-52b2d01077c3a190';
    addthis.init();
}
*/
/**
 * Creates a blurry background for the hero image, based on the hero image itself.
 * @param {String} jsUriStackBlur The URI to the StackBlur javascript.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeBlurryHeroBackground(jsUriStackBlur) {
    var iPadClient = false; 
    try { iPadClient = navigator.userAgent.match(/iPad/i) != null; } catch(err) {}

    try {
        //console.log('starting blurry hero background ...');
        //$(function() {
            if (bigScreen && !iPadClient) {
                if (!nonResIE()) {
                    if (Modernizr.cssfilters) {
                        // CSS approach
                        //console.log('cssfilter support detected ...');
                        $('.article-hero').append( $('.article-hero-content > figure > img').clone() );
                    } else {
                        //console.log('cssfilter support missing, using canvas ...');
                        // Canvas approach
                        $.getScript(jsUriStackBlur, function() {
                            $('.article-hero').append('<canvas class="article-hero-bg" id="hero-bg" width="200" height="200" data-canvas></canvas>');
                            //$('.article-hero').append('<canvas class="article-hero-bg" id="hero-bg" width="200" height="200" data-canvas></canvas><div id="hero-canvas-overlay"></div>');
                            // Change this value to adjust the amount of blur
                            var BLUR_RADIUS = 16;

                            var canvas = document.getElementById('hero-bg');//querySelector('[data-canvas]');
                            var canvasContext = canvas.getContext('2d');

                            var image = new Image();
                            image.src = $('.article-hero-content > figure > img').attr('src');// document.querySelector('[data-canvas-image]').src;

                            var drawBlur = function() {
                                var w = canvas.width;
                                var h = canvas.height;
                                canvasContext.drawImage(image, 0, 0, w, h);
                                stackBlurCanvasRGBA('hero-bg', 0, 0, w, h, BLUR_RADIUS);
                            };

                            image.onload = function() {
                                // draw the blurry image using stackblur
                                drawBlur();
                                // add top-to-bottom gradient, use the same color as
                                // the header
                                var linGrad = canvasContext.createLinearGradient(0, 0, 0, 30);
                                linGrad.addColorStop(0, 'rgba(14,19,31,1)');
                                linGrad.addColorStop(1, 'rgba(14,19,31,0)');
                                canvasContext.fillStyle = linGrad;
                                canvasContext.fillRect(0, 0, canvasContext.canvas.width, canvasContext.canvas.height);
                            };
                        });
                        //console.log('done with blurry hero background ...');
                    }
                } else { // css blur filter (ms-filter)
                    $('.article-hero').append( $('.article-hero-content > figure > img').clone() );
                }
            }
        //});
    } catch (err) {
        //console.log('error creating blurry hero background: ' + err);
        return false;
    }
    return true;
}

/**
 * Makes tables responsive.
 * @see http://zurb.com/playground/projects/responsive-tables
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeResponsiveTables() {
    try {
	var switched=false;var updateTables=function(){if(($(window).width()<767)&&!switched){switched=true;$("table.responsive").each(function(i,element){splitTable($(element));});return true;}
	else if(switched&&($(window).width()>767)){switched=false;$("table.responsive").each(function(i,element){unsplitTable($(element));});}};$(window).load(updateTables);$(window).bind("resize",updateTables);function splitTable(original)
	{original.wrap("<div class='table-wrapper' />");var copy=original.clone();copy.find("td:not(:first-child), th:not(:first-child)").css("display","none");copy.removeClass("responsive");original.closest(".table-wrapper").append(copy);copy.wrap("<div class='pinned' />");original.wrap("<div class='scrollable' />");}
	function unsplitTable(original){original.closest(".table-wrapper").find(".pinned").remove();original.unwrap();original.unwrap();}
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Makes tabbed content.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeTabs() {
    try {
        // Set the default active tab (make it the first one)
        var firstTab = $('.tabbed .tab').first();
        var hash = window.location.hash.substring(1);
        if (!(hash === 'refs' || hash === 'links'))
            firstTab.addClass('active-tab');
        // set the height
        var height = firstTab.outerHeight();
        
        // Process each tabbed section
        $('.tabbed').each(function(e) {
            // calculate a more correct top offset for the tab content boxes
            var tabContentTopOffset =   $(this).children('.tabbed-heading').first().outerHeight() +              $(this).find('.tab-link').first().outerHeight();
            console.log('heading: ' +   $(this).children('.tabbed-heading').first().outerHeight() + ', tab: ' +  $(this).find('.tab-link').first().outerHeight());
            
            // iterate all the tab content boxes
            $(this).find('.tab-content').each(function(e) {
                // find the tallest one
                var thisTabHeight = $(this).children().first().outerHeight();
                console.log('tab content height is ' + thisTabHeight + '. new max? ' + (thisTabHeight > height));
                if (thisTabHeight > height) {
                    height = thisTabHeight;
                }
                
                // set the top offset (some browsers, e.g. chrome, need a little less than others, e.g. firefox)
                $(this).css({ top : (tabContentTopOffset-2)+'px' });
            });
            
            // set the height equal to the tallest one's height, plus a little extra (wrapper's padding etc.)
            $(this).css({ height : (height+125)+'px' });
        });
        
	$('.tabbed .tab .tab-link').click(function(e) {
            e.preventDefault();
            $('.tabbed .tab').removeClass('active-tab');
            $(this).parent('.tab').addClass('active-tab');
            
            /*var clone = $(this).next('.tab-content').clone();
            clone.attr('style', 'display:block; position:relative; left:-9999px; top:-9999px;');
            var tabContentHeight = clone.height();
            clone.remove();*/
            
            /*var tabContentHeight = $(this).next('.tab-content').children().first().height();
            console.log('setting tabbed height to ' + (tabContentHeight+90) + 'px');
            $(this).parents('.tabbed').first().attr('style', 'height:'+ (tabContentHeight+90) + 'px');*/
	});
    } catch (err) {
        return false;
    }
    return true;
}
/**
 * Makes tooltips on elements with data-tooltip or data-hoverbox attributes.
 * @param {String} cssUri The URI to the qTip css.
 * @param {String} jsUri The URI to the qTip javascript.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeTooltips(cssUri, jsUri) {
    try {
        if ($('[data-tooltip]')[0] || $('[data-hoverbox]')[0]) {
            $('head').append('<link rel="stylesheet" href="' + cssUri + '" type="text/css" />');
            $.getScript(jsUri, function() {
                $('[data-tooltip]').each(function() { 
                    $(this).qtip({ 
                        content: $(this).attr('data-tooltip'), 
                        style: {
                            classes:'qtip-tipsy qtip-shadow'
                        },
                        position: {
                            my:'bottom center',
                            at:'top center',
                            viewport: $(window)
                        }
                    }); 
                });
                $('[data-hoverbox]').each(function() {
                    var showDelay = $(this).hasClass('featured-link') ? 1000 : 250; // Long delay on "card links" in portal pages, short delay on the rest
                    $(this).qtip({
                        content: $(this).attr('data-hoverbox'), 
                        title: $(this).attr('data-hoverbox-title'),
                        style: {
                            classes:'qtip-light qtip-shadow'
                        },
                        position: {
                            my: 'bottom center',
                            at: 'top center',
                            viewport: $(window)
                        },
                        show: {
                            event: 'focus mouseenter',
                            delay: showDelay,
                            effect: function() {
                                $(this).fadeTo(400, 1);
                            }
                        },
                        hide: {
                            event: 'blur mouseleave',
                            fixed: true,
                            delay: 400,
                            effect: function() {
                                $(this).fadeTo(400, 0);
                            }
                        }
                    });
                });
            });
        }
    } catch (err) {
        return false;
    }
    return true;
}
/**
 * Makes an animated scroll-to effect for on-page links.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function makeScrollToSmooth() {
    try {
        //$('a[href*=#]:not([href=#])').click(function() { // Apply to all on-page links
        $('.reflink,.scrollto').click(function() {
            if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') || location.hostname == this.hostname) {
                var hashStr = this.hash.slice(1);
                var target = $(this.hash);
                target = target.length ? target : $('[name=' + hashStr +']');

                if (target.length) {
                    $('html,body').animate({ scrollTop: target.offset().top - 20}, 500);
                    window.location.hash = hashStr;
                    return false;
                }
            }
        });
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Makes ready Highslide, by loading the necessary css/js if necessary.
 * @param {String} cssUri The URI to the Highslide css.
 * @param {String} jsUri The URI to the Highslide javascript.
 * @returns {Boolean} True if no error is thrown, false if not.
 */
function readyHighslide(cssUri, jsUri) {
    try {
        if ($(".highslide")[0]){
            $('head').append('<link rel="stylesheet" type="text/css" href="' + cssUri + '" />');
            $('head').append('<script type="text/javascript" src="' + jsUri +'" async />');
        }
    } catch (err) {
        return false;
    }
    return true;
}

/**
 * Things to do when the document is ready
 */
$(document).ready( function() {
	// responsive tables
        makeResponsiveTables();
        // tabbed content (enhancement - works with pure css but not optimal)
        makeTabs();

	// Add style definition for links: No outlines for mouse navigation, dotted outlines for keyboard navigation
	/*$('head').append('<style id="_outlines" />');
	$('body').attr('onmousedown', 'hideOutlines()');
	$('body').attr('onkeydown', 'showOutlines()');*/
	
	var fmsg = false;
	/*
	// Hide small screen navigation if necessary & show big screen navigation if necessary
    if (!nonResIE()) { // IE versions that cannot chew media queries will get a non-responsive version, so those should always have the big screen navigation available
        var ssNavBreakpoint = getSmallScreenBreakpoint(); // Viewport widths equal to or below this value will use small screen navigation
        var slideDuration = 200; // Animation time (milliseconds): Toggle small screen navigation
        var scrollWidth = getScrollbarWidth();
        var visibleWidth = getVisibleWidth();//$(window).width() + scrollWidth;

        if (visibleWidth <= ssNavBreakpoint) {// && ("#nav_sticky").css("display") == "block") {
            $("#nav_sticky").hide();
        }

        $("#nav_toggle").click(function() {
            $("#nav_sticky").slideToggle(slideDuration);
        });
		
        $(window).resize(function() {
            visibleWidth = getVisibleWidth();//$(window).width() + scrollWidth; // NB refresh value on resize
			var searchBoxFocus = $("#query").is(":focus");
			//if (visibleWidth > ssNavBreakpoint && $("#nav_sticky").css("display") != "block") { // original
            //if (visibleWidth > getSmallScreenBreakpoint() && $("#nav_sticky").css("display") != "block") {
			if (!isSmallScreen() && $("#nav_sticky").css("display") != "block") {
                $("#nav_sticky").show();
            }
            //else if (visibleWidth <= ssNavBreakpoint && $("#nav_sticky").css("display") == "block") { // original
			//else if (visibleWidth <= getSmallScreenBreakpoint() && $("#nav_sticky").css("display") == "block") {
			else if (isSmallScreen() && $("#nav_sticky").css("display") == "block" && !searchBoxFocus) {
                $("#nav_sticky").hide();
            }
        });
    }
	*/
    
    /*
    // "Hide" the left column when it doesn't contain anything
	if (document.getElementById("leftside")) {
		if ($("#leftside").html()) {
			if ($.trim($("#leftside").html()) == '') {
				//if (!$("#leftside").html().trim()) {
					$("#leftside").css("width", "0");
					$("#content").css("width", "100%");
				//}
			}
		}
	}*/
    
	/*
    $("#nav_toggler").click(function () {
        //var contentWidth = $("#content").css("width"); // Store the CSS-defined width, complete with unit, e.g. "75%"
		//alert(contentWidth);
		
        if ($("#leftside").css("display") == "none") { // Show navigation
			$("#nav_top_wrap").slideToggle(300);
            //$("#nav_top_wrap").slideToggle(300, function() { $("#sm-links-top").fadeIn(); });
            $("#leftside").css({"display" : "block"});
            if (!emptyOrNonExistingElement("leftside")) {
                $("#leftside").animate({
                        marginLeft: "0"
                    }, 250, function(){});
                $("#content").animate({
                        width: "78%"
						//width: contentWidth
                    }, 250, function(){ });
            }
            $(this).addClass("pinned"); // Toggle the class
            $.post("/settings", { pinned_nav: "true" }); // Store the navbar visibility state in the user session
        } 
        
        else { // Hide navigation
			$("#nav_top_wrap").slideToggle(300);
            //$("#sm-links-top").fadeOut(50, function() { $("#nav_top_wrap").slideToggle(300); });
            $("#leftside").css({"display" : "none"});
            if (!emptyOrNonExistingElement("leftside")) {
                $("#leftside").animate({
                        marginLeft: "-500px"
                    }, 250, function(){});
                $("#content").animate({
                        width: "100%"
                    }, 250, function(){  });
            }
            $(this).removeClass("pinned"); // Toggle the class
            $.post("/settings", { pinned_nav: "false" }); // Store the navbar visibility state in the user session
        }
    });
	
	// Make menu togglers keyboard accessible
	$(document).keyup(function(e){
		if (e.keyCode == 13 && $(document.activeElement).attr("id") == "nav_toggler") {
			$("#nav_toggler").click();
		} else if (e.keyCode == 13 && $(document.activeElement).attr("id") == "nav_toggle") {
			$("#nav_toggle").click();
		}
	});
	*/
	
	/*
	// Expand the main content to the left when the left column is empty or missing
	// REMOVED: Can't do this safely because it often contains js-injected content
	if (emptyOrNonExistingElement('leftside')) {
        alert("Empty or non-existing #leftside, hiding it.");
        $("#leftside").css("width", "0");
        $("#leftside").css("height", "0");
        $("#content").css("width", "100%");
    }
	*/
	/*
	// Expand the main content to the right when the right column is empty or missing
    if (emptyOrNonExistingElement('rightside')) {
        //alert("Empty or non-existing #rightside, hiding it.");
        $(".main-content").css("width", "100%");
        $("#rightside").css("width", "0");
        $("#rightside").css("height", "0");
    }
	// Expand the main content area vertically, so the footer will be normal-sized even on very short pages
	//if (!($("body").height() > $(window).height()) && !isSmallScreen()) { // if not vertical scrollbar
	if (!($(document).height() > $(window).height()) && !isSmallScreen()) { // if not vertical scrollbar & not smallscreen
		//var extraHeight = 64;
		//var extraHeight = 50;
		var extraHeight = 45;
		var mainContentHeight = $(window).height() - $("#header").height() - $("#footer").height() - extraHeight; // [viewport height] - [header height] - [footer height] - [value found by trial-and-error]
		//$("#docwrap").animate({height: mainContentHeight+"px"}, 600);
		//$("#docwrap").height(mainContentHeight);
		$("#docwrap").css("min-height", mainContentHeight+"px");
	}
	*/
	
	// qTip tooltips
        //makeTooltips();
	
        
	// Animated verical scrolling to on-page locations
	makeScrollToSmooth();
	
	// Add facebook-necessary attribute to the html element
	$("html").attr('xmlns:fb', 'http://ogp.me/ns/fb#"');
	
	// Format tables
	makeNiceTables();
	
	// Fragment-based highlighting
	//$(".reflink").click(function() { highlightReference(); }); // On click 
	$("a").click(function() { highlightReference(); }); // On click (it's not sufficient to track only .reflink clicks - that will cause any previous highlighting to stick "forever")
	highlightReference(); // On page load
	
	// "Read more"-links
	// Reg. version: a full-width bar button
	$(".cta.more").append('<i class="icon-right-open-big"></i>');
	// Alt. version: a "tab" under a line (uses a span inside the link)
	//$(".cta.more > span").append('<i class="icon-right-open-big"></i>');
	//$(".cta.more:not(:has(span))").append('<i class="icon-right-open-big"></i>').css('padding', '0.5em'); // In case there are any without span child
	
	// Initialize toggleable content
    initToggleables();
	
	// Social sharers
	/*
	$("#share_button_top").attr('displayText','Del denne siden');
    $("#share_button_facebook").attr('displayText','Facebook');
    $("#share_button_twitter").attr('displayText','Twitter');
    $("#share_button_gplus").attr('displayText','Google+');
    $("#share_button_email").attr('displayText','E-post');
    $("#share_button_bottom").attr('displayText','Mer ...');
	*/
	
	// Overlay logos (if necessary)
	//$('<span class="overlay-logo"><img src="/images/logos/logo-fram-f-20.png" /></span>').insertAfter('.featured-box.logo-fram img');
	//$('<span class="overlay-logo"><img src="/images/logos/logo-ice-20.png" /></span>').insertAfter('.featured-box.logo-ice img');
	
	/*
	try {
		$("#slides").carouFredSel({
				width: "100%",
				height: "59%",
				direction: "left",
				circular: true,
				responsive: true,
				auto: 6500,
				items: {
						visible: 1,
						width: "90",
						height: "variable"
				},
				scroll: {
						fx: "crossfade",
						duration: 500,
						pauseOnHover: true
				},
				prev: {
						button: "#featured-prev",
						key: "left"
				},
				next: {
						button: "#featured-next",
						key: "right"
				},
				pagination: "#featured .pagination"
		});
	} catch (err) {}
	*/
	/*
	try {
		// Make image maps responsive
		$('img[usemap]').rwdImageMaps(); // Scale image maps (note: this should be the LAST call in $(document).ready(...))
	} catch (err) {}
	*/
	
	// AddThis
	//loadAddThis();
});


/**
 * Highslide settings
 */
try {
	//hs.align = 'center';
	//hs.marginBottom = 10;
	//hs.marginTop = 10;
	hs.marginBottom = 50; // Make room for the "Share" widget
	hs.marginTop = 50; // Make room for the thumbstrip
	hs.marginLeft = 50;
	hs.marginRight = 50; 
	//hs.maxHeight = 600;
	//hs.outlineType = 'rounded-white';
	hs.outlineType = 'drop-shadow';
	
	hs.lang = {
		loadingText :     'Laster...',
		loadingTitle :    'Klikk for å avbryte',
		focusTitle :      'Klikk for å flytte fram',
		fullExpandText :  'Full størrelse',
		fullExpandTitle : 'Utvid til full størrelse',
		creditsText :     'Drevet av <i>Highslide JS</i>',
		creditsTitle :    'Gå til hjemmesiden til Highslide JS',
		previousText :    'Forrige',
		previousTitle :   'Forrige (pil venstre)',
		nextText :        'Neste',
		nextTitle :       'Neste (pil høyre)',
		moveText :        'Flytt',
		moveTitle :       'Flytt',
		closeText :       'Lukk',
		closeTitle :      'Lukk (esc)',
		resizeTitle :     'Endre størrelse',
		playText :        'Spill av',
		playTitle :       'Vis bildeserie (mellomrom)',
		pauseText :       'Pause',
		pauseTitle :      'Pause (mellomrom)',
		number :          'Bilde %1 av %2',
		restoreTitle :    'Klikk for å lukke bildet, klikk og dra for å flytte. Bruk piltastene for forrige og neste.'
	};
} catch (err) {
	// Highslide probably undefined
}