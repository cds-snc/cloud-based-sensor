FROM mcr.microsoft.com/vscode/devcontainers/python:3.11-buster@sha256:d04396715a7033a36a3bd03d7eb490923fda1bbb562ecd290c2b23c71b30db85

ARG USERNAME=vscode

# Set these in devcontainer.json
ARG TERRAFORM_VERSION
ARG AWS_CLI_VERSION
ARG TERRAGRUNT_VERSION

# Install packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends build-essential ca-certificates curl git gnupg2 jq libffi-dev make openssh-client vim zsh \
    && apt-get autoremove -y && apt-get clean -y 

# Install Terraform
RUN curl -Lo terraform.zip https://releases.hashicorp.com/terraform/"${TERRAFORM_VERSION}"/terraform_"${TERRAFORM_VERSION}"_linux_"$(dpkg --print-architecture)".zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Terragrunt
ARG TERRAGRUNT_SRC=https://github.com/gruntwork-io/terragrunt/releases/download
RUN curl -Lo terragrunt ${TERRAGRUNT_SRC}/v"${TERRAGRUNT_VERSION}"/terragrunt_linux_"$(dpkg --print-architecture)" \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/

# Install Checkov
RUN pip3 install --upgrade requests setuptools \
    && pip3 install --upgrade botocore checkov

RUN curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/awscli/examples
    
# Setup aliases and autocomplete
RUN echo "\n\
complete -C /usr/bin/aws_completer aws\n\
complete -C /usr/local/bin/terraform terraform\n\
complete -C /usr/local/bin/aws_completer aws\n\
alias tf='terraform'\n\
alias tg='terragrunt'\n\
alias ll='la -la'" >> /home/"${USERNAME}"/.zshrc