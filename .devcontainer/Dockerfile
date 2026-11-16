FROM fedora:44

# Avoid interactive prompts and update base system
RUN dnf -y upgrade --refresh && \
    dnf -y install \
    @development-tools \
    gcc \
    gcc-c++ \
    gdb \
    clang \
    llvm \
    cmake \
    ninja-build \
    nasm \
    nodejs \
    npm \
    python3 \
    python3-pip \
    python3-devel \
    python3-setuptools \
    python3-wheel \
    golang \
    java-latest-openjdk-devel \
    maven \
    sqlite \
    postgresql \
    mariadb \
    git \
    curl \
    wget \
    unzip \
    tar \
    sudo \
    which \
    procps-ng \
    icu \
    libicu \
    krb5-libs \
    openssl-libs \
    zlib && \
    dnf clean all

# Install latest .NET SDK via Microsoft's official installer script
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel STS --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet && \
    rm -f /tmp/dotnet-install.sh

# Install Gradle directly from official release archive
ARG GRADLE_VERSION=8.12
RUN curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    ln -s "/opt/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle && \
    rm -f /tmp/gradle.zip

# Install Ollama CLI and Starship prompt
RUN curl -fsSL https://ollama.com/install.sh | sh && \
    curl -sS https://starship.rs/install.sh | sh -s -- -y

# Create non-root 'vscode' user with passwordless sudo
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

# Copy custom Starship config and enable in Bash
RUN mkdir -p ~/.config && \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
COPY --chown=$USERNAME:$USERNAME starship.toml /home/$USERNAME/.config/starship.toml

# Install latest Rust toolchain via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV GOPATH="/home/${USERNAME}/go"
ENV GOTOOLCHAIN=local
ENV PATH="/home/${USERNAME}/.cargo/bin:${GOPATH}/bin:${PATH}"