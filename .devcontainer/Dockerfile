FROM ubuntu:24.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (Java 17 is standard for Flutter in 2026)
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa openjdk-17-jdk \
    wget python3 adb usbutils \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME
ENV PATH="$PATH:$FLUTTER_HOME/bin"

# Set up Android SDK (Command Line Tools Only)
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/tools.zip && \
    unzip /tmp/tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm /tmp/tools.zip

ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

# Accept Android Licenses and install platform-tools
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools"

# Configure bash with git branch in prompt and auto-completion
RUN echo '\n\
# Git branch in prompt\n\
parse_git_branch() {\n\
    git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/(\\1)/"\n\
}\n\
\n\
# Colorful prompt with git branch\n\
export PS1="\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\[\\033[01;33m\\]\\$(parse_git_branch)\\[\\033[00m\\]\\$ "\n\
\n\
# Enable git auto-completion\n\
if [ -f /usr/share/bash-completion/completions/git ]; then\n\
    . /usr/share/bash-completion/completions/git\n\
fi' >> /root/.bashrc

WORKDIR /workspace