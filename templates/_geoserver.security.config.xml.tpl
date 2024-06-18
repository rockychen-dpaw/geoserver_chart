{{- define "geoserver.security.config.xml" }}<security>
  <roleServiceName>default</roleServiceName>
  <authProviderNames>
    <string>default</string>
  </authProviderNames>
  <configPasswordEncrypterName>strongPbePasswordEncoder</configPasswordEncrypterName>
  <encryptingUrlParams>false</encryptingUrlParams>
  <filterChain>
    <filters name="web" class="org.geoserver.security.HtmlLoginFilterChain" interceptorName="interceptor" exceptionTranslationName="exception" path="/web/**,/gwc/rest/web/**,/" disabled="false" allowSessionCreation="true" ssl="false" matchHTTPMethod="false">
      <filter>rememberme</filter>
      <filter>nginx_sso</filter>
      <filter>form</filter>
      <filter>anonymous</filter>
    </filters>
    <filters name="webLogin" class="org.geoserver.security.ConstantFilterChain" path="/j_spring_security_check,/j_spring_security_check/" disabled="false" allowSessionCreation="true" ssl="false" matchHTTPMethod="false">
      <filter>form</filter>
    </filters>
    <filters name="webLogout" class="org.geoserver.security.LogoutFilterChain" path="/j_spring_security_logout,/j_spring_security_logout/" disabled="false" allowSessionCreation="false" ssl="false" matchHTTPMethod="false">
      <filter>formLogout</filter>
    </filters>
    <filters name="rest" class="org.geoserver.security.ServiceLoginFilterChain" interceptorName="restInterceptor" exceptionTranslationName="exception" path="/rest/**" disabled="false" allowSessionCreation="false" ssl="false" matchHTTPMethod="false">
      <filter>nginx_sso</filter>
      <filter>basic</filter>
      <filter>anonymous</filter>
    </filters>
    <filters name="gwc" class="org.geoserver.security.ServiceLoginFilterChain" interceptorName="restInterceptor" exceptionTranslationName="exception" path="/gwc/rest/**" disabled="false" allowSessionCreation="false" ssl="false" matchHTTPMethod="false">
      <filter>nginx_sso</filter>
      <filter>basic</filter>
    </filters>
    <filters name="default" class="org.geoserver.security.ServiceLoginFilterChain" interceptorName="interceptor" exceptionTranslationName="exception" path="/**" disabled="false" allowSessionCreation="false" ssl="false" matchHTTPMethod="false">
      <filter>nginx_sso</filter>
      <filter>basic</filter>
      <filter>anonymous</filter>
    </filters>
  </filterChain>
  <rememberMeService>
    <className>org.geoserver.security.rememberme.GeoServerTokenBasedRememberMeServices</className>
    <key>geoserver</key>
  </rememberMeService>
  <bruteForcePrevention>
    <enabled>true</enabled>
    <minDelaySeconds>1</minDelaySeconds>
    <maxDelaySeconds>5</maxDelaySeconds>
    <maxBlockedThreads>100</maxBlockedThreads>
    <whitelistedMasks>
      <string>127.0.0.1</string>
    </whitelistedMasks>
  </bruteForcePrevention>
</security>
{{- end}}
