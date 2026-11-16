FROM fedora:latest

# Avoid interactive prompts and update base system
RUN dnf -y upgrade --refresh && \
    # Install build-essentials equivalents, compilers, runtimes, and SQL clients
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
    golang \
    java-latest-openjdk-devel \
    maven \
    gradle \
    dotnet-sdk-9.0 \
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
    procps-ng && \
    dnf clean all

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
ENV PATH="/home/${USERNAME}/.cargo/bin:/home/${USERNAME}/go/bin:${PATH}"

# Install common Go & Python dev tools
RUN go install golang.org/x/tools/gopls@latest && \
    pip3 install --user --upgrade pip setuptools wheel