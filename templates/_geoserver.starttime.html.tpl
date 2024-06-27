{{- define "geoserver.starttime.html" }}<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
</head>
<body>
<table style="width:100%;height:100%;text-align:center;v-align:center">
<tr><td>
<table style="width:100%">
<tr><th style="text-align:right">Geoserver began to start at </th><td><span id="starttime"></span></td></tr>
<tr><th style="text-align:right">Geoserver was ready at </th><td><span id="readytime"></span></td></tr>
<tr><th style="text-align:right">Geoserver spent </th><td><span id="startingtime"></span></td></tr>
<tr><th style="text-align:right">Geoserver will restart at  </th><td><span id="nextrestarttime"></span></td></tr>
</table>
</td></tr>
</table>
</body>
</html>
{{- end}}
