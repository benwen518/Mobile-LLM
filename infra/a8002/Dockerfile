FROM ghcr.io/snapdragon-toolchain/arm64-android:v0.3

ARG DEBIAN_FRONTEND=noninteractive
ARG ANDROID_CMDLINE_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    GRADLE_HOME=/opt/gradle/gradle-8.9 \
    PATH=/opt/gradle/gradle-8.9/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-ndk-r28b/toolchains/llvm/prebuilt/linux-x86_64/bin:${PATH}

RUN mkdir -p /usr/share/man/man1 \
    && apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git git-lfs openssh-server openjdk-17-jdk-headless \
      android-tools-adb rsync tmux unzip procps lsof \
    && rm -rf /var/lib/apt/lists/*

COPY vendor/commandlinetools-linux-15859902_latest.zip /tmp/android-commandline-tools.zip
COPY vendor/gradle-8.9-bin.zip /tmp/gradle-8.9-bin.zip

RUN echo "${ANDROID_CMDLINE_SHA256}  /tmp/android-commandline-tools.zip" | sha256sum -c - \
    && mkdir -p /opt/android-sdk/cmdline-tools /opt/gradle \
    && unzip -q /tmp/android-commandline-tools.zip -d /opt/android-sdk/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && unzip -q /tmp/gradle-8.9-bin.zip -d /opt/gradle \
    && yes | sdkmanager --licenses >/dev/null \
    && sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" \
    && rm -f /tmp/android-commandline-tools.zip /tmp/gradle-8.9-bin.zip \
    && mkdir -p /run/sshd /root/.ssh /workspace /models \
    && chmod 700 /root/.ssh \
    && ssh-keygen -A

COPY sshd-mobile-ai.conf /etc/ssh/sshd_config.d/90-mobile-ai.conf
COPY entrypoint.sh /usr/local/bin/mobile-ai-entrypoint
RUN chmod 0755 /usr/local/bin/mobile-ai-entrypoint

WORKDIR /workspace
EXPOSE 22
ENTRYPOINT ["/usr/local/bin/mobile-ai-entrypoint"]
CMD ["/usr/sbin/sshd", "-D", "-e"]


