FROM ubuntu:noble

ENV GRADLE_VERSION 8.11.1
ENV GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
ENV ANDROID_COMMANDLINE_URL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_BUILDTOOLS_VERSION=35.0.1
ENV ANDROID_SDK_PACKAGE_NAME "platforms;android-35"
ENV ANDROID_SDK_ROOT /opt/android-sdk-linux
ENV ANDROID_NDK_HOME /opt/android-ndk
ENV ANDROID_NDK_VERSION r27c
ENV ANDROID_NDK_URL=https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux.zip
ENV GOLANG_URL https://go.dev/dl/go1.24.2.linux-$(dpkg --print-architecture).tar.gz

# Dependencies to execute Android builds
RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-21-jdk-headless gcc wget curl git ca-certificates unzip

RUN cd /opt \
    && wget -q ${ANDROID_COMMANDLINE_URL} -O android-commandline-tools.zip \
    && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && unzip -q android-commandline-tools.zip -d /tmp/ \
    && mv /tmp/cmdline-tools/ ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm android-commandline-tools.zip && ls -la ${ANDROID_SDK_ROOT}/cmdline-tools/latest/

ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin

RUN yes | sdkmanager --licenses

RUN touch /root/.android/repositories.cfg

# Emulator and Platform tools
RUN yes | sdkmanager "platform-tools"
RUN yes | sdkmanager --update --channel=0
RUN yes | sdkmanager "${ANDROID_SDK_PACKAGE_NAME}"
RUN yes | sdkmanager "build-tools;${ANDROID_BUILDTOOLS_VERSION}"
ENV PATH=$PATH:"/opt/android-sdk-linux/build-tools/${ANDROID_BUILDTOOLS_VERSION}":"/opt/gradle/gradle-${GRADLE_VERSION}/bin/"

RUN wget ${GRADLE_URL} -P /tmp \
    && unzip -d /opt/gradle /tmp/gradle-*.zip \
    && chmod +775 /opt/gradle \
    && gradle --version \
    && rm -rf /tmp/gradle*

RUN mkdir /opt/android-ndk-tmp && \
    cd /opt/android-ndk-tmp && \
    wget -O ndk.zip -q ${ANDROID_NDK_URL} && \
    unzip -q ndk.zip && \
    mv ./android-ndk-${ANDROID_NDK_VERSION} ${ANDROID_NDK_HOME} && \
    cd ${ANDROID_NDK_HOME} && \
    rm -rf /opt/android-ndk-tmp

# add to PATH
ENV PATH ${PATH}:${ANDROID_NDK_HOME}

RUN wget -O /tmp/golang.tar.gz ${GOLANG_URL}

RUN tar -C /usr/local -xzf /tmp/golang.tar.gz
RUN rm /tmp/golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN apt-get clean

RUN wget https://github.com/ebourg/jsign/releases/download/6.0/jsign-6.0.jar -O /usr/local/jsign-6.0.jar
