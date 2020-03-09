#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

FROM python:3.7.6-buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Uncomment the following COPY line and the corresponding lines in the `RUN` command if you wish to
# include your requirements in the image itself. It is suggested that you only do this if your
# requirements rarely (if ever) change.
COPY requirements.txt /tmp/pip-tmp/

# RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
#   && echo 'Asia/Shanghai' >/etc/timezone


# ENV DEBIAN_FRONTEND noninteractive # debian-keyring
# ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
# RUN apt-key adv --no-tty --recv-keys --keyserver keyserver.ubuntu.com AA8E81B4331F7F50
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 AA8E81B4331F7F50
RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb https:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
# RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# Chanage to aliyun mirrors
# 更新apt-get源, aliyun 会导致apt-utils dialog的错误
# RUN echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main non-free contrib" > /etc/apt/sources.list && \
#     echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main non-free contrib" >> /etc/apt/sources.list  && \
#     echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main" >> /etc/apt/sources.list && \
#     echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main" >> /etc/apt/sources.list && \
#     echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list && \
#     echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main non-free contrib" >> /etc/apt/sources.list && \
#     echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list && \
#     echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main non-free contrib" >> /etc/apt/sources.list

# Configure apt and install packages
RUN apt-get update && apt-get upgrade -qqy && apt-get -qqy install --no-install-recommends apt-utils \
    bzip2 \
    ca-certificates \
    sudo \
    unzip \
    wget \dialog 2>&1 \
    #
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed
    && apt-get -y install git iproute2 procps lsb-release \
    #y
    # Install pylint
    && pip --disable-pip-version-check --no-cache-dir install pylint \
    #
    # Update Python environment based on requirements.txt
    && pip --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-tmp \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*


#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
# RUN apt-get update -qqy \
#   && apt-get -qqy --no-install-recommends install \
#     bzip2 \
#     ca-certificates \
#     sudo \
#     unzip \
#     wget \
#   && rm -rf /var/lib/apt/lists/* 

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*


#=================================
# Chrome Launch Script Wrapper
#=================================
# COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
# RUN chmod 755 /opt/bin/wrap_chrome_binary
# RUN /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION="latest"
RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
  && echo "Using chromedriver version: "$CD_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
  && sudo ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

ENV PYTHONIOENCODING=utf-8

RUN mkdir -p /app
WORKDIR /app

CMD ["/bin/bash"]
