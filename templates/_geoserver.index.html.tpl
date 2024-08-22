{{- define "geoserver.index.html" }}<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
</head>
<body>
   <div style="margin-top:50px;margin-left:50px">
   <h3><A href="/geoserver/web">Geoserver Home Page</A>
   <br>
   <A href="/geoserver/www/server/serverinfo.html" target="geoserver_info">Geoserver Info</A>
   <br>
   <A href="/geoserver/www/server/reports/reports.html" target="geoserver_healthcheck_reports">Geoserver Healthcheck Reports</A>
   <br>
   <A href="/geoserver/www/server/starthistory.html" target="geoserver_start_hisotry">Geoserver Start History</A>
   <br>
   <A href="/geoserver/www/server/liveness.log" target="geoserver_liveness_log">Geoserver Liveness Log</A>
   </h3>
   </div>
</body>
</html>
{{- end}}
