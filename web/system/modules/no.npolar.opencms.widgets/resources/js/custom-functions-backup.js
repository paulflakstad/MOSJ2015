////////////////////////////////////////////////////////////////////////////////
//
//                  Custom functions for the StringSuggest widget
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
        try { paramTitle = _.where(obj.titles, filter)[0]['title']; } catch (err) {}
    }
    
    var uniqueId = generateUid();
    /*String*/var s = '<p id="' + uniqueId + '">Loading time series info ...';
    try {
        var paramId = obj.id;
        var dataObj = {
            'q': paramId,
            'format':'json',
            'variant':'array',
            'fields':'titles,id',
            'facets':'false'
        }
        $.ajax({
            url: 'http://apptest.data.npolar.no:9000/monitoring/timeseries/',
            data: dataObj,
            dataType: 'jsonp',
            success: function(data) {
                var tsInfo = '<em>Includes time series:</em><ul>';
                _.each(data, function(singleEntry) {
                    //if (consoleDebugging) console.log('getTimeSeriesForParam: _each is now at ' + singleEntry.id);//JSON.stringify(singleEntry));
                    tsInfo += '<li>' + singleEntry.id + '<br/>';
                    var title = '[Unkown title]';
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
                    tsInfo += title + '</li>';
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
    s += '</p>';
    
    return s;
}
/**
 * Creates a unique ID.
 */
function generateUid(separator) {
    var delim = separator || "-";
    function S4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    return (S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4());
}