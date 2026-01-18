FROM ubuntu:24.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (Java 17 is standard for Flutter in 2026)
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa openjdk-17-jdk \
    wget python3 adb usbutils && rm -rf /var/lib/apt/lists/*

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
# Update package manager cache, install cmake build tool, and clean up apt cache to reduce image size.
# This follows Docker best practices by combining multiple commands in a single RUN instruction
# to minimize layer count and keep the final image lean.
# Automatically answer 'yes' to all prompts during package installation,
# allowing apt-get to proceed without waiting for user confirmation.
# This is essential in Docker builds where interactive prompts cannot be handled.
RUN apt-get update && apt-get install cmake -y && apt-get install ninja-build -y && rm -rf /var/lib/apt/lists/*
# Accept Android Licenses
RUN yes | sdkmanager --licenses

WORKDIR /workspace