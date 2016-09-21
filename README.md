# MOSJ website framework (2015 relauch)

Website framework for [Environmental Monitoring Svalbard and Jan Mayen (MOSJ)](http://www.mosj.no/en/).

**(C) Paul-Inge Flakstad / Norwegian Polar Institute.**

The MOSJ website is powered by OpenCms, and utilizes data pulled from the [Norwegian Polar Data Centre](https://data.npolar.no/) via its API.

Dependencies:
- `[no.npolar.util](https://github.com/paulflakstad/no.npolar.util)` is used all over the place
- `[no.npolar.data.api](https://github.com/paulflakstad/no.npolar.data.api)` is used on the indicator template
- [Custom widgets](https://github.com/paulflakstad/opencms-module-customwidgets) are implemented on indicator pages
- [Alkacon OAMP weboptimization module v2.0.0](https://github.com/alkacon/alkacon-oamp/tree/master/com.alkacon.opencms.v8.weboptimization) is used to minify css
- [Highcharts](http://www.highcharts.com/)
- Several `no.npolar.common` modules are also employed:
 - `.category`
 - `.commentimages`
 - `.gallery`
 - `.highslide`
 - `.ivorypage`
 - `.jquery`
 - `.lang`
 - `.menu`
 - `.newsbulletin`
 - `.pageelements`
 - `.portalpage`
 - `.resourcelist`
 - `.videoresource`
