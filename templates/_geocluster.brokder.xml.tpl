{{- define "geocluster.broker.xml" }}<?xml version="1.0" encoding="UTF-8"?>
<beans
    xmlns="http://www.springframework.org/schema/beans"
    xmlns:amq="http://activemq.apache.org/schema/core"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
                        http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd">
  <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer"/>
  <broker useJmx="true" xmlns="http://activemq.apache.org/schema/core">

    <amq:persistenceAdapter>
      <kahaDB directory="${activemq.base}/kahadb" lockKeepAlivePeriod="0" />
    </amq:persistenceAdapter>


    <networkConnectors xmlns="http://activemq.apache.org/schema/core">
      <networkConnector uri="static:(tcp://host1:61616,tcp://host2:61616,tcp://host3:61616,tcp://localhost:61616)" />
    </networkConnectors>

    <transportConnectors>
      <transportConnector name="openwire" uri="${activemq.transportConnectors.server.uri}" />
    </transportConnectors>
  </broker>
</beans>
{{- end}}
