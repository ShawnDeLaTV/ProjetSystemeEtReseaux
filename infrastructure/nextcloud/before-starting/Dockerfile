FROM nextcloud:latest

COPY ca.crt /usr/local/share/ca-certificates/monorg-ca.crt
RUN apt-get update && apt-get install -y ca-certificates 
RUN update-ca-certificates
