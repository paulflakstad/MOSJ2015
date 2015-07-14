////////////////////////////////////////////////////////////////////////////////
//
//                          	Custom functions
//                          
////////////////////////////////////////////////////////////////////////////////
/**
 * Gets info on the time series for a specific parameter described in the given
 * object. 
 * 
 * Expects language info in the "extra" argument (if not null), e.g.: "lang=en".
 */
function getTimeSeriesForParam(/*Object*/obj, /*String*/extra) {
    var filter = null;
    if (extra !== null) {
        extra = replaceAll(extra, "lang=no", "lang=nb"); // OpenCms uses "no", the API uses "nb" ...
        filter = getFilter(extra.split('&'));
        //if (consoleDebugging) console.log('getTimeSeriesForParam: filter is ' + JSON.stringify(filter));
    }
    
    var paramTitle = null;
    if (filter !== null) {
        try { paramTitle = _.where(obj.titles, filter)[0]['text']; } catch (err) {}
    }
    
    var uniqueId = generateUid();
    // This is the info container
    /*String*/var s = '<p id="' + uniqueId + '">Loading time series info ...';
    try {
        // Create the filter-id query, e.g. 'id1|id2|id3|id4'
        var queryStringTimeSeriesIds = ''; 
        _.each(obj.timeseries, function(timeSeriesEntry) {
            queryStringTimeSeriesIds += (queryStringTimeSeriesIds.length > 0 ? '|' : '') + getIdFromUrl(timeSeriesEntry);
        });
        
        //if (consoleDebugging) console.log('getTimeSeriesForParam: querying for IDs ' + queryStringTimeSeriesIds);

        // Crete the query data object
        var queryData = {
            'q': '',
            'format':'json',
            'variant':'array',
            'fields':'titles,id',
            'filter-id':queryStringTimeSeriesIds
        }
        $.ajax({
            url: '//api.npolar.no/indicator/timeseries/',
            data: queryData,
            dataType: 'jsonp',
            success: function(responseData) {
                var tsInfo = '<em>Includes time series:</em><ul>';
                _.each(responseData, function(singleEntry) {
                    //if (consoleDebugging) console.log('getTimeSeriesForParam: _each is now at ' + singleEntry.id);//JSON.stringify(singleEntry));
                    tsInfo += '<li>';
                    var title = '[Unknown title]';
                    try {
                        var titlesArr = singleEntry.titles;
                        // Filter out matches
                        titlesArr = _.where(titlesArr, filter);
                        title = titlesArr[0].title;
                    } catch(err) {
                        title = singleEntry.titles[0].title;
                    }
                    if (paramTitle !== null) {
                        title = replaceAll(title, ' / '+paramTitle, '');
                    }
                    tsInfo += '<span style="color:#000; font-weight:bold;">' + title + '</span>';
                                        tsInfo += '<br /><span style="color:#777;">' + singleEntry.id + '</span>';
                                        tsInfo += '</li>';
                });
                tsInfo += '</ul>';
                // Update the HTML of the info container we created earlier
                $('#'+uniqueId).html(tsInfo);
            },
            error: function( request, status, error ) {
                if (consoleDebugging) console.log('getTimeSeriesForParam: Querying service failed (' + status + '). Error was: ' + error);
            }
        });
    } catch (err) {
        s += 'ERROR: ' + err;
    }
    // OLD VERSION
    /*
    try {
        var paramId = obj.id;
        var dataObj = {
            'q': paramId,
            'format':'json',
            'variant':'array',
            'fields':'titles,id'
        }
        $.ajax({
            url: 'http://api.npolar.no/indicator/timeseries/',
            data: dataObj,
            dataType: 'jsonp',
            success: function(data) {
                var tsInfo = '<em>Includes time series:</em><ul>';
                _.each(data, function(singleEntry) {
                    //if (consoleDebugging) console.log('getTimeSeriesForParam: _each is now at ' + singleEntry.id);//JSON.stringify(singleEntry));
                    tsInfo += '<li>';
                    var title = '[Unknown title]';
                    try {
                        var titlesArr = singleEntry.titles;
                        // Filter out matches
                        titlesArr = _.where(titlesArr, filter);
                        title = titlesArr[0].text;
                    } catch(err) {
                        title = singleEntry.titles[0].text;
                    }
                    if (paramTitle !== null) {
                        title = replaceAll(title, ' / '+paramTitle, '');
                    }
                    tsInfo += '<span style="color:#000; font-weight:bold;">' + title + '</span>';
					tsInfo += '<br /><span style="color:#777;">' + singleEntry.id + '</span>';
					tsInfo += '</li>';
                });
                tsInfo += '</ul>';
                $('#'+uniqueId).html(tsInfo);
            },
            error: function( request, status, error ) {
                if (consoleDebugging) console.log('getTimeSeriesForParam: Querying service failed (' + status + '). Error was: ' + error);
            }
        });
    } catch (err) {
        s += 'ERROR: ' + err;
    }
    //*/
    s += '</p>';
    
    return s;
}
/**
 * Extracts the ID from a URL that ends with an ID.
 * 
 * @param {String} urlEndingWithId An URL ending with an ID.
 * @returns {String} The ID.
 */
function getIdFromUrl(/*String*/urlEndingWithId) {
    try {
        var breakdown = urlEndingWithId.split('/');
        return breakdown[breakdown.length-1];
    } catch (err) {
        return 'NO-ID';
    }
}
/**
 * Creates a unique ID.
 * 
 * @param String separator The separator to use, defaults to "-".
 */
function generateUid(/*String*/ separator) {
    var delim = separator || "-";
    function S4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    return (S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4());
}

/**
 * Splits the given string on ampersand. Used to convert a string formatted like 
 * an URL query part into an array with entries like "key=value".
 * 
 * @param String keyValPairsStr
 * @returns String[]
 */
function /*String[]*/ getKeyValuePairs(/*String*/keyValPairsStr) {
    return keyValPairsStr.split('&');
}

/**
 * Example function: Applying %(__function:myAwesomeFunction) in a template will
 * result in the template calling this function and injecting the returned value.
 * 
 * In the real world, you would do something with the info provided by the given
 * object. For example, you could do an AJAX request, fetching info on related 
 * stuff, based on an ID.
 */
function myAwesomeFunction(/*Object*/obj) {
    console.log(JSON.stringify(obj)); // Look at your console to see what info is present in obj
    return "Awesome!"; // Will be injected anywhere %(__function:myAwesomeFunction) is used
}