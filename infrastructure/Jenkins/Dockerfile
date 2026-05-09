FROM jenkins/jenkins:lts

USER root

COPY ca.crt /usr/local/share/ca-certificates/monorg-ca.crt

RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates && keytool -importcert -noprompt -alias monorg-ca -file /usr/local/share/ca-certificates/monorg-ca.crt -keystore /opt/java/openjdk/lib/security/cacerts -storepass changeit

COPY jenkins.yaml /var/jenkins_home/casc_configs/jenkins.yaml
RUN chown -R jenkins:jenkins /var/jenkins_home/casc_configs/

USER jenkins

RUN jenkins-plugin-cli --plugins oic-auth role-strategy configuration-as-code

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false