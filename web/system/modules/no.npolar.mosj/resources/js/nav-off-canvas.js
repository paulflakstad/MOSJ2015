/**
* Off-canvas navigation: Triggers, actions and so on.
*/

var large = 800;
var extraHeight = 100;
var bigScreen = true;  // Default: Browsers with no support for matchMedia (like IE9 and below) will use this value
try {
	bigScreen = window.matchMedia('(min-width: ' + large + 'px)').matches; // Update value for browsers supporting matchMedia
} catch (err) {
	// Retain default value
}

/**
 * Add styles for keyboardd accessibility.
 */
function styleForKeys() {
	try { document.getElementById('_outlines').innerHTML=''
		+ 'a:focus, input:focus, button:focus, select:focus { '
			+ 'outline:thin dotted; outline:2px solid orange; '
		+ '} '
		+ '#nav, #nav ul { '
			+ (!bigScreen ? 'display:none; ' : 'display:block !important; ')
		+ '} '
		+ '#nav ul ul, #nav.visible ul ul, #nav.visible ul ul.visible {'
			+ (!bigScreen ? '' : 'display:none !important; ')
		+ '} '
		+ '#nav.visible, #nav.visible #nav_topmenu, #nav.visible ul.visible { '
			+ 'display:block; '
		+ '}'; } 
	catch (err) {}
}
/**
 * Remove styles for keyboard accessibility.
 */
function  styleForKeyless() {
	try { document.getElementById('_outlines').innerHTML='a, a:focus, input:focus, select:focus { outline:none !important; } #nav, #nav > ul { display:block; }'; } catch (err) {}
}

/**
 * Is the off-canvas navigation currently in view?
 */
function smallScreenMenuIsVisible() {
	return !bigScreen && $('#nav').hasClass('visible');
}


/**
 * Stuff to do once the page has loaded.
 */
$(document).ready(function(e) {
	
	// Initial setup
	__init();
	
	// Apply class and inline max-height to all lists that are children of a navigation item that is "in path" (= part of the current breadcrumb)
	/*$("li.inpath > ul").addClass("visible").each(function() {
		$(this).attr("style", getMaxHeightVal($(this)));
	});*/
	$('#nav ul ul').addClass('not-visible');
	$('#nav li.inpath > ul').toggleClass('visible not-visible');
	$('#nav ul.visible').each(function() {
		$(this).attr('style', getMaxHeightVal($(this)));
	});
	
	// Clicks on "show/hide main navigation"
	$('#toggle-search').click(function(e) {	
		var search = $('#searchbox');
		search.removeAttr('style');
		$('html').toggleClass('search-open')
		search.toggleClass('not-visible');
	});
	
	// Clicks on "show/hide main navigation"
	$('#toggle-nav, #close-nav').click(function(e) {		
		$('html').toggleClass('nav-open')
		var nav = $('#nav');
		nav.toggleClass('visible');
		
		if (nav.hasClass('visible')) {
			setTimeout(function () { 
				// Apply inline max-height to visible menus (more on this below)
				nav.attr('style', getMaxHeightVal($('#nav')));
			}, 600);
		} else {
			nav.removeAttr('style');
		}
	});
	
	// Clicks on "show/hide subitems" inside the navigation
	$('.toggle-subitems').click(function(e) {
		// Set a class: This will allow easy styling the "button" 
		$(this).toggleClass('close');
		var submenu = $(this).next('ul');
		submenu.removeAttr('style'); // First, remove any previously inserted max-height override
		
		if (submenu.hasClass('visible') || submenu.hasClass('not-visible')) {
			submenu.toggleClass('visible not-visible'); // Toggle visibility class
		}
		else {
			submenu.addClass('visible');
		}
			
		// After a submenu was expanded ("opened")
		if (submenu.hasClass('visible')) {
			
			// If we just made the submenu visible, it now has a class with a huge default "max-height" value (e.g. 9999px). 
			// That means there will be a delay when hiding it again (because it will animate the max-height down from that huge value to zero). 
			// To fix, we apply the actual height as max-height, inline, thereby overriding the huge default value in the stylesheet.
			
			// First of all, remove any already applied inline max-height values on all parent lists, allowing them to expand naturally
			submenu.parents('li.subitems').parent("ul").attr('style', 'max-height:9999px !important;');
			$('#nav').attr('style', 'max-height:9999px !important;');
			
			// Use a timeout to ensure the "slide open" animation has completed before we modify the max-height.	
			setTimeout(function () { 
				// Apply the max-height fix on the list the user just opened
				submenu.attr('style', getMaxHeightVal(submenu));
				//submenu.attr("style", "max-height:"+submenu.innerHeight()+"px !important;");
				// Then update the max-height on all parent lists
				submenu.parents('li.subitems').parent('ul').each(function () {
					$(this).attr('style', getMaxHeightVal($(this)));
					//$(this).attr("style", "max-height:"+$(this).innerHeight()+"px !important;");
				});
				$('#nav').attr('style', getMaxHeightVal($('#nav')));
				//$("#nav").attr("style", "max-height:"+$("#nav").innerHeight()+"px !important;");
			}, 600);
			
				
		} else {
		}
	});
	
	// Handle case: User tabs through the navigation, and eventually past the last element, "skipping" back to the main content. In these cases, the menu should close.
	$('#docwrap').focusin(function () {
		if (smallScreenMenuIsVisible()) {
			$('#toggle-nav').click();
		}
	});
	
	// Handle case: User clicks/taps on the main content while the menu is visible. In these cases, the menu should close.
	$('#docwrap').click(function() {
		if (smallScreenMenuIsVisible()) {
			$('#toggle-nav').click();
		}
	});
	
	$(window).resize(function() {
		layItOut();
	});
});

function getMaxHeightVal(jqueryElem) {
	return "max-height:"+ (jqueryElem.innerHeight() + extraHeight) + "px !important;";
}

function __init() {
	var root = $('html');
	root.addClass('jsready csstransforms3d csstransitions');
	
	$('head').append('<style id="_outlines" />');
	$('body').attr('onmousedown', 'styleForKeyless()');
	//$('body').attr('onkeydown', 'styleForKeys()');
	$('body').bind('keydown', function(e) {
		if (e.keyCode == 9) {
			styleForKeys();
		}
	});
	
	//root.addClass("jsready");
	if (bigScreen) {
		// Large viewport
	}
	else {
		// Small viewport
		//$("#nav").removeClass("visible");
		$('#nav .subitems > a').after('<a href="javascript:void(0)" class="toggle-subitems"></a>'); // NEW
		$('#nav .inpath > .toggle-subitems').addClass("close");
	}	
	
	layItOut();
}

function layItOut() {
	try {
		bigScreen = window.matchMedia('(min-width: ' + large + 'px)').matches; // Update value for browsers supporting matchMedia
	} catch (err) {
		// Retain default value
	}
	if (bigScreen) {
		// Large viewport
		/*if (!$("#nav").hasClass("visible")) {
			$("#nav").addClass("visible");
		}*/
		
		// Create the large screen submenu: 
		// Clone the current top-level navigation's submenu, add it to the DOM and wrap it in a <nav>
		if (emptyOrNonExistingElement('subnavigation')) { // Don't keep adding the submenu again and again ... Du-uh
			var submenu = $('.inpath.subitems > ul').clone(); // Clone it
			submenu.removeAttr('class').removeAttr('style'); // Strip classes and attributes (which may have been modified by togglers in small screen view)
			submenu.children('ul').removeAttr('class').removeAttr('style'); // Do the same for all deeper levels
			//submenu.insertBefore('#content').wrap('<nav id="subnavigation" role="navigation" />'); // Add the submenu to the DOM, wrapped
			$('#leftside').append('<nav id="subnavigation" role="navigation"><ul>' + submenu.html() + '</ul></nav>');
		}
		$('#searchbox').removeAttr('class');
		$('#searchbox').removeAttr('style');
	}
	else {
		//$('#nav').prepend('<a id="close-nav">X</a>');
		// Small viewport
		//$('#nav').removeClass('visible');
		//$('#nav').removeAttr('style');
		
		$('#subnavigation').remove(); // Remove the big screen submenu
		$('#searchbox').hide(); // Prevent "search box collapse" animation on page load
		//$('#searchbox').attr('style', 'display:none;'); // Prevent search box collapsing animation on page load
		$('#searchbox').addClass('not-visible');
		
		var nav = $('#nav');
	}
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