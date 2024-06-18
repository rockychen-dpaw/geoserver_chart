{{- define "geoserver.security.filter.nginx_sso.config.xml" }}<requestHeaderAuthentication>
  <id>554ceb2b:18f0f4f773a:-7ffb</id>
  <name>nginx_sso</name>
  <className>org.geoserver.security.filter.GeoServerRequestHeaderAuthenticationFilter</className>
  <roleSource class="org.geoserver.security.config.PreAuthenticatedUserNameFilterConfig$PreAuthenticatedUserNameRoleSource">Header</roleSource>
  <rolesHeaderAttribute>x-groups</rolesHeaderAttribute>
  <principalHeaderAttribute>x-email</principalHeaderAttribute>
</requestHeaderAuthentication>
{{- end}}
