FROM debian:bullseye-slim as installer
ARG EXE_FILENAME=awscli-exe-linux-x86_64.zip
RUN apt-get update \
  && apt-get install -y unzip gnupg software-properties-common curl \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
  && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  && apt-get update \
  && apt-get install terraform \
  && curl "https://awscli.amazonaws.com/${EXE_FILENAME}" -o ${EXE_FILENAME} \
  && unzip $EXE_FILENAME \
  && ./aws/install --bin-dir /aws-cli-bin/

FROM debian:bullseye-slim

WORKDIR /work

RUN apt-get update -y \
  && apt-get install -y git less groff \
  && apt-get clean all
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer /usr/bin/terraform/ /usr/local/bin/
