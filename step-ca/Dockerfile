FROM alpine:3.20

ARG STEP_CLI_VERSION=0.28.7
ARG STEP_CA_VERSION=0.28.4

RUN apk add --no-cache curl ca-certificates openssl bash wget tar jq && update-ca-certificates

# step-cli
RUN wget -q https://github.com/smallstep/cli/releases/download/v${STEP_CLI_VERSION}/step_linux_${STEP_CLI_VERSION}_amd64.tar.gz && \
    tar -xzf step_linux_${STEP_CLI_VERSION}_amd64.tar.gz && \
    mv step_*/bin/step /usr/local/bin/ && \
    rm -rf step_*

# step-ca
RUN wget -q https://github.com/smallstep/certificates/releases/download/v${STEP_CA_VERSION}/step-ca_linux_${STEP_CA_VERSION}_amd64.tar.gz && \
    tar -xzf step-ca_linux_${STEP_CA_VERSION}_amd64.tar.gz && \
    mv step-ca /usr/local/bin/ && \
    rm -f step-ca_linux_${STEP_CA_VERSION}_amd64.tar.gz

RUN adduser -D -h /home/step step

WORKDIR /home/step

COPY --chown=step:step entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

USER step

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]