{{- define "geoserver.security.filter.nginx_sso.config.xml" }}<requestHeaderAuthentication>
{{- $nginxSSO := $.Values.geoserver.nginxSSO | default dict }}
  <id>554ceb2b:18f0f4f773a:-7ffb</id>
  <name>nginx_sso</name>
  <className>org.geoserver.security.filter.GeoServerRequestHeaderAuthenticationFilter</className>
  <roleSource class="org.geoserver.security.config.PreAuthenticatedUserNameFilterConfig$PreAuthenticatedUserNameRoleSource">{{ $nginxSSO.roleSource | default "Header" }}</roleSource>
  <userGroupServiceName>{{ $nginxSSO.userGroupServiceName | default "default" }}</userGroupServiceName>
  <roleServiceName>{{ $nginxSSO.roleServiceName | default "default" }}</roleServiceName>
  <rolesHeaderAttribute>x-groups</rolesHeaderAttribute>
  <principalHeaderAttribute>x-email</principalHeaderAttribute>
</requestHeaderAuthentication>
{{- end}}
