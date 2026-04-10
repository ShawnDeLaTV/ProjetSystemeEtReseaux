FROM jenkins/jenkins:lts

# Install plugins non-interactively
RUN jenkins-plugin-cli --plugins oic-auth 

# Disable setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false