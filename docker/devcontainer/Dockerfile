# https://mcr.microsoft.com/en-us/product/devcontainers/base/about
FROM mcr.microsoft.com/devcontainers/base:dev-ubuntu-22.04

RUN apt-get update && \
    apt-get install -y \
      default-mysql-client \
      bash-completion \
      procps \
      net-tools \
      iputils-ping \
      locales \
      make \
      jq \
      fzf \
      vim \
      curl \
      wget \
      git \
      groff \
      less \
      sudo \
      gcc

# ロケール設定
RUN echo 'ja_JP.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=ja_JP.UTF-8
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# aws cli インストール
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# kubectl インストール
# https://kubernetes.io/ja/docs/tasks/tools/install-kubectl/
RUN curl -LO https://dl.k8s.io/release/v1.22.6/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# eksctl インストール
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin

# terraform インストール (version 1.5.* が必要)
# https://developer.hashicorp.com/terraform/install
RUN wget https://releases.hashicorp.com/terraform/1.8.0/terraform_1.8.0_linux_amd64.zip && \
    unzip terraform_1.8.0_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    terraform -install-autocomplete 

# helmインストール
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    helm completion bash > /etc/bash_completion.d/helm

# helmのリポジトリにeksのチャート追加
RUN helm repo add eks https://aws.github.io/eks-charts && \
    helm repo update

# Flux CLI インストール
RUN curl -s https://fluxcd.io/install.sh | sudo bash