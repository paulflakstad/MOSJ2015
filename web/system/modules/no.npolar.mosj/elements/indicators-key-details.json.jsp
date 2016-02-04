<%-- 
    Document   : indicators-key-details
    Description: Outputs a JSON describing all MOSJ indicator pages. 
                    A "locale" parameter is required.
    Created on : Feb 4, 2016
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.file.*,
                no.npolar.util.*,
                no.npolar.common.menu.*,
                no.npolar.data.api.mosj.*,
                java.util.*,
                org.opencms.flex.CmsFlexController,
                org.opencms.main.*,
                org.opencms.json.*,
                org.opencms.jsp.*,
                org.opencms.util.*,
                org.opencms.security.CmsRole"
                session="true"
%><%!
static final String NO_TITLE = "NO TITLE";
static final String NO_DESCR = "NO DESCR";
/*
public List<CmsResource> sortByTitle(List<CmsResource> list, CmsObject cmso) throws CmsException {
    final CmsObject c = cmso;
    Collections.sort(list, new Comparator<CmsResource>() {
        public int compare(CmsResource o1, CmsResource o2) {
            try {
                return c.readPropertyObject(o1, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE).compareTo(c.readPropertyObject(o2, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE));
            } catch (Exception e) {
                return 0;
            }
        }
    });
    return list;
}
//*/

public String normalize(String str) {
    String s = str.toLowerCase();
    if (s.contains("ian polar inst") || s.contains("sk polarinst")) {
        return makeJSON("Norwegian Polar Institute", 
                "http://www.npolar.no/en/", 
                "Norsk Polarinstitutt", 
                "http://www.npolar.no/");
    }
    if (s.contains("governor") || s.contains("sysselmann")) {
        return makeJSON("The Governor of Svalbard", 
                "http://www.sysselmannen.no/en/", 
                "Sysselmannen på Svalbard", 
                "http://www.sysselmannen.no/");
    }
    if (s.contains("marine research") || s.contains("havforsk")) {
        return makeJSON("Institute of Marine Research", 
                "http://www.imr.no/en", 
                "Havforskningsinstituttet", 
                "http://www.imr.no/");
    }
    if (s.contains("(nilu)") || s.contains("air research") || s.contains("luftforskning")) {
        return makeJSON("Norwegian Institute for Air Research (NILU)", 
                "http://www.nilu.no/Forsiden/tabid/41/language/en-GB/Default.aspx", 
                "Norsk institutt for luftforskning (NILU)", 
                "http://www.nilu.no/");
    }
    if (s.contains("met.no") || s.contains("meteorologi")) {
        return makeJSON("Norwegian Meteorological Institute", 
                "http://www.met.no/English/", 
                "Meteorologisk institutt", 
                "http://www.met.no/");
    }
    if (s.contains("(nina)") || s.contains("nature res") || s.contains("naturforsk")) {
        return makeJSON("The Norwegian Institute for Nature Research (NINA)", 
                "http://www.nina.no/english/Home", 
                "Norsk institutt for naturforskning (NINA) ", 
                "http://www.nina.no/");
    }
    if (s.contains("(nifes)") || s.contains("nutrition and seafood") || s.contains("institutt for ernæring")) {
        return makeJSON("National Institute of Nutrition and Seafood Research (NIFES)", 
                "http://nifes.no/en/", 
                "Nasjonalt institutt for ernærings- og sjømatforskning", 
                "http://nifes.no/");
    }
    if (s.contains("(nrpa)") || s.contains("radiation") || s.contains("strålevern")) {
        return makeJSON("Norwegian Radiation Protection Authority (NRPA)", 
                "http://www.nrpa.no/en/", 
                "Statens strålevern", 
                "http://www.nrpa.no/");
    }
    
    if (s.contains("visit svalbard")) {
        return makeJSON("Visit Svalbard AS", 
                "http://www.visitsvalbard.com/en/", 
                "Visit Svalbard AS", 
                "http://www.visitsvalbard.com/");
    }
    return null;
}

public String makeJSON(String enName, String enUrl, String noName, String noUrl) {
    return "{ \"lang\" : \"en\", \"name\" : \"" + enName + "\", \"url\" : \"" + enUrl + "\" },"
            + "{ \"lang\" : \"no\", \"name\" : \"" + noName + "\", \"url\" : \"" + noUrl + "\" }";
}
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();

// Muy importante!!! (One of "application/json" OR "application/javascript")
CmsFlexController.getController(request).getTopResponse().setHeader("Content-Type", "application/json; charset=utf-8");

out.println("{");

String listFolderUri = request.getParameter("locale");

if (listFolderUri == null || listFolderUri.isEmpty()) {
    listFolderUri = "no";
}

Locale locale = null;
try {
    locale = new Locale(listFolderUri);
} catch (Exception e) {
    out.println("\"error\":\"Invalid value for parameter 'locale'.\"");
    out.println("}");
    return;
}

listFolderUri = "/" + listFolderUri + "/";

if (!cmso.existsResource(listFolderUri)) {
    out.println("\"error\":\"There is no content in " + locale.getDisplayName(new Locale("en")) + ".\"");
    out.println("}");
    return;
}

out.println("\"indicators\":[");

final boolean LIST_SUBTREE = true;
CmsResourceFilter filterIndictorFiles = CmsResourceFilter.DEFAULT_FILES.addRequireType(OpenCms.getResourceManager().getResourceType("mosj_indicator").getTypeId());
List<CmsResource> indicatorFiles = cmso.readResources(listFolderUri, filterIndictorFiles, LIST_SUBTREE);
//indicatorFiles = sortByTitle(indicatorFiles, cmso);
Iterator<CmsResource> iIndicatorFiles = null;

if (!indicatorFiles.isEmpty()) {
    iIndicatorFiles = indicatorFiles.iterator();
    
    while (iIndicatorFiles.hasNext()) {
        CmsResource indicatorFile = iIndicatorFiles.next();
        String iTitle = cmso.readPropertyObject(indicatorFile, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(NO_TITLE);
        String iUri = cmso.getSitePath(indicatorFile);
        
        List<CmsResource> siblings = cmso.readSiblings(indicatorFile, CmsResourceFilter.DEFAULT_FILES);
        
        out.print("{");
        out.print("\n\"title\" : \"" + iTitle + "\", ");
        out.print("\n\"id\" : \"" + cmso.readResource(iUri).getResourceId() + "\", ");
        out.print("\n\"website_urls\" : [");
            Iterator<CmsResource> iSiblings = siblings.iterator();
            while (iSiblings.hasNext()) {
                CmsResource sibling = iSiblings.next();
                out.print("\n{"
                            + "\n\"lang\" : \"" + OpenCms.getLocaleManager().getDefaultLocale(cmso, sibling).getLanguage() + "\","
                            + "\n\"url\" : \"" + OpenCms.getLinkManager().getOnlineLink(cmso, cmso.getSitePath(sibling)) + "\""
                        + "\n}" + (iSiblings.hasNext() ? "," : ""));
            }
        out.print("\n],");
        //out.print("\n\"url\" : \"" + OpenCms.getLinkManager().getOnlineLink(cmso, iUri) + "\", ");
        out.print("\n\"parameters\" : [");
        
        
        Map<String, String> rightsMapping = new HashMap<String, String>();
        
        I_CmsXmlContentContainer structuredContent = cms.contentload("singleFile", cmso.getSitePath(indicatorFile), false);
        while (structuredContent.hasMoreResources()) {
            I_CmsXmlContentContainer mosjMonitoringData = cms.contentloop(structuredContent, "MonitoringData");
            //int monitoringDataLoopCount = 0;
                
            //boolean firstItemPrinted = false;
            while (mosjMonitoringData.hasMoreResources()) {
                //monitoringDataLoopCount++;
                
                //String parameters = "[";
                //String params = "";
                String rightsOwnerObj = "";

                I_CmsXmlContentContainer mosjMonitoringDataDetails = cms.contentloop(mosjMonitoringData, "Details");
                if (mosjMonitoringDataDetails.hasMoreResources()) {
                    I_CmsXmlContentContainer parameterExecutiveInstitutions = cms.contentloop(mosjMonitoringDataDetails, "ExecutiveInstitutions");
                    while (parameterExecutiveInstitutions.hasMoreResources()) {
                        String rightsOwnerName = cms.contentshow(parameterExecutiveInstitutions, "Text");
                        String rightsOwnerURL = cms.contentshow(parameterExecutiveInstitutions, "URL");
                        
                        String rightsOwnerObjNormalized = normalize(rightsOwnerName);
                        if (rightsOwnerObjNormalized != null) {
                            rightsOwnerObj += rightsOwnerObjNormalized;
                        } else {
                            rightsOwnerObj += "\n{ \"name\" : \"" + rightsOwnerName + "\"";
                            if (CmsAgent.elementExists(rightsOwnerURL)) {
                                rightsOwnerObj += ",\n\"url\" : \"" + rightsOwnerURL + "\"";
                            }
                            rightsOwnerObj += "\n}";
                        }
                        
                        rightsOwnerObj += ",";
                    }
                    // Remove the comma after the last object
                    if (rightsOwnerObj.endsWith(",")) {
                        rightsOwnerObj = rightsOwnerObj.substring(0, rightsOwnerObj.length()-1);
                    }
                }
                
                I_CmsXmlContentContainer mosjParameters = cms.contentloop(mosjMonitoringData, "Parameter");

                //int parametersLoopCount = 0; // Parameter counter
                String parameterIDs = "";
                while (mosjParameters.hasMoreResources()) {
                    //parametersLoopCount++;

                    // Parameter ID
                    String pid = cms.contentshow(mosjParameters, "ID");
                    boolean validParameterId = pid.matches("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}");

                    // ID validity check
                    if (validParameterId) {
                        parameterIDs += "\n\"" + pid + "\",";
                    }
                } // while (parameters)
                if (parameterIDs.endsWith(",")) {
                    parameterIDs = parameterIDs.substring(0, parameterIDs.length()-1);
                }

                if (!parameterIDs.isEmpty() && !rightsOwnerObj.isEmpty()) {
                    rightsMapping.put(rightsOwnerObj, rightsMapping.containsKey(rightsOwnerObj) ? (rightsMapping.get(rightsOwnerObj) + "," + parameterIDs) : parameterIDs);
                }
                /*    
                    //params += "\n\"parameters\" : [";
                        params += ",\n{ \"provided_by\" : [";
                            params += rightsOwner;
                        params += "\n],";
                        params += "\n\"ids\" : [";
                            params += parameterIDs;
                        params += "\n]\n}";
                    //params += "\n]";
                }
                
                if (!params.isEmpty()) {
                    if (!firstItemPrinted) {
                        params = params.substring(1);
                    }
                    out.print(params);
                    firstItemPrinted = true;
                }
                //*/
            } // monitoring data loop
            
            Iterator<String> iRights = rightsMapping.keySet().iterator();
            while (iRights.hasNext()) {
                String rightsOwner = iRights.next();
                out.print("\n{ \"provided_by\" : [");
                    out.print(rightsOwner);
                out.print("\n],");
                out.print("\n\"ids\" : [");
                    out.print(rightsMapping.get(rightsOwner));
                out.print("\n]\n}" + (iRights.hasNext() ? "," : ""));
            }
        }
        out.print("\n]"); // end parameters array
        out.print("\n}".concat(iIndicatorFiles.hasNext() ? ", " : "")); // end indicator
    }
    
}

out.print("\n]");
out.print("\n}");
%>