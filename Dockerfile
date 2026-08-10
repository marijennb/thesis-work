FROM columbiasld/esp:centos7-full

USER root

# --------------------------------------------------------------------
# CentOS 7 is EOL.
# Replace the dead mirrorlist repositories with the CentOS Vault.
# --------------------------------------------------------------------
RUN rm -f /etc/yum.repos.d/CentOS-Base.repo && \
    cat > /etc/yum.repos.d/CentOS-Base.repo <<'EOF'
[base]
name=CentOS-7 - Base
baseurl=https://vault.centos.org/centos/7/os/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-7 - Updates
baseurl=https://vault.centos.org/centos/7/updates/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-7 - Extras
baseurl=https://vault.centos.org/centos/7/extras/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# Clean old yum metadata
RUN yum clean all && \
    rm -rf /var/cache/yum && \
    yum makecache

# --------------------------------------------------------------------
# System dependencies
#
# NOTE:
# CentOS 7's Tcl/Tk 8.5 stays installed.
# We only need its general build/X11 dependencies here.
# --------------------------------------------------------------------
RUN yum install -y \
    libyaml \
    libyaml-devel \
    dtc \
    git \
    which \
    wget \
    make \
    gcc \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    libX11-devel \
    libXft-devel \
    libXrender-devel \
    fontconfig-devel \
    && yum clean all

# --------------------------------------------------------------------
# Tcl/Tk 8.6
#
# CentOS 7 ships Tcl/Tk 8.5, which is too old for the version of
# CustomTkinter used by current ESP.
#
# Install Tcl/Tk 8.6 separately under /opt/tcltk86.
# DO NOT replace the CentOS system Tcl/Tk.
# --------------------------------------------------------------------
ARG TCLTK_VERSION=8.6.18
ENV TCLTK_PREFIX=/opt/tcltk86

# Build Tcl 8.6
RUN cd /tmp && \
    wget -O tcl${TCLTK_VERSION}-src.tar.gz \
        https://downloads.sourceforge.net/project/tcl/Tcl/${TCLTK_VERSION}/tcl${TCLTK_VERSION}-src.tar.gz && \
    tar -xzf tcl${TCLTK_VERSION}-src.tar.gz && \
    cd tcl${TCLTK_VERSION}/unix && \
    ./configure \
        --prefix=${TCLTK_PREFIX} \
        --enable-threads && \
    make -j$(nproc) && \
    make install && \
    rm -rf \
        /tmp/tcl${TCLTK_VERSION} \
        /tmp/tcl${TCLTK_VERSION}-src.tar.gz

# Build Tk 8.6 against the Tcl 8.6 installation above
RUN cd /tmp && \
    wget -O tk${TCLTK_VERSION}-src.tar.gz \
        https://downloads.sourceforge.net/project/tcl/Tcl/${TCLTK_VERSION}/tk${TCLTK_VERSION}-src.tar.gz && \
    tar -xzf tk${TCLTK_VERSION}-src.tar.gz && \
    cd tk${TCLTK_VERSION}/unix && \
    CPPFLAGS="-I${TCLTK_PREFIX}/include" \
    LDFLAGS="-L${TCLTK_PREFIX}/lib -Wl,-rpath,${TCLTK_PREFIX}/lib" \
    ./configure \
        --prefix=${TCLTK_PREFIX} \
        --with-tcl=${TCLTK_PREFIX}/lib \
        --enable-threads && \
    make -j$(nproc) && \
    make install && \
    rm -rf \
        /tmp/tk${TCLTK_VERSION} \
        /tmp/tk${TCLTK_VERSION}-src.tar.gz


# --------------------------------------------------------------------
# Make Tcl/Tk 8.6 discoverable by programs built afterwards.
#
# LD_LIBRARY_PATH also makes sure the runtime loader finds our
# privately installed Tcl/Tk instead of CentOS 7's 8.5.
# --------------------------------------------------------------------
ENV PATH="${TCLTK_PREFIX}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${TCLTK_PREFIX}/lib:${LD_LIBRARY_PATH}"

# --------------------------------------------------------------------
# Python 3.9
#
# CentOS 7 SCL does not provide rh-python39, so build a separate
# Python installation without touching CentOS' system Python.
# And build Python explicitly against /opt/tcltk86.
# --------------------------------------------------------------------
ARG PYTHON_VERSION=3.9.25

RUN cd /tmp && \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    CPPFLAGS="-I${TCLTK_PREFIX}/include" \
    LDFLAGS="-L${TCLTK_PREFIX}/lib -Wl,-rpath,${TCLTK_PREFIX}/lib" \
    ./configure \
        --prefix=/opt/python39 \
        --with-ensurepip=install \
        --with-tcltk-includes="-I${TCLTK_PREFIX}/include" \
        --with-tcltk-libs="-L${TCLTK_PREFIX}/lib -ltk8.6 -ltcl8.6" && \
    make -j$(nproc) && \
    make install && \
    rm -rf \
        /tmp/Python-${PYTHON_VERSION} \
        /tmp/Python-${PYTHON_VERSION}.tgz

# Put Python 3.9 first in PATH.
ENV PATH="/opt/python39/bin:${PATH}"

# --------------------------------------------------------------------
# Verify that Python really linked against Tcl/Tk 8.6.
#
# This makes the Docker build FAIL immediately if Python accidentally
# picks CentOS's Tcl/Tk 8.5 again.
# --------------------------------------------------------------------
RUN python3 - <<'PY'
import tkinter
import _tkinter

print("Python:", __import__("sys").version)
print("_tkinter:", _tkinter.__file__)
print("Tcl:", tkinter.TclVersion)
print("Tk:", tkinter.TkVersion)

assert tkinter.TclVersion >= 8.6, \
    "Python was built against an old Tcl version"

assert tkinter.TkVersion >= 8.6, \
    "Python was built against an old Tk version"
PY


# --------------------------------------------------------------------
# Python packages required by ESP.
# --------------------------------------------------------------------
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install \
        customtkinter \
        Pmw

# --------------------------------------------------------------------
# Final sanity checks -- @TODO: REMOVE!
# --------------------------------------------------------------------
RUN python3 - <<'PY'
import tkinter
import customtkinter
import Pmw

print("Tcl version:", tkinter.TclVersion)
print("Tk version:", tkinter.TkVersion)
print("CustomTkinter import: OK")
print("Pmw import: OK")
PY

USER espuser
WORKDIR /home/espuser/esp
