FROM registry.access.redhat.com/ubi9/python-312 AS builder

ARG NEXUS_USER
ARG NEXUS_PASS
ARG NEXUS_PYPI_URL

ENV PIP_DEFAULT_TIMEOUT=120

WORKDIR /app

USER root
RUN dnf install -y rust cargo openssl-devel python3-devel gcc && dnf clean all
USER 1001

COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /tmp/wheels \
    --index-url "https://${NEXUS_USER}:${NEXUS_PASS}@${NEXUS_PYPI_URL}/simple/" \
    --trusted-host "$(echo ${NEXUS_PYPI_URL} | cut -d'/' -f1)" \
    --timeout 120 \
    -r requirements.txt

FROM registry.access.redhat.com/ubi9/python-312

WORKDIR /app

USER root
RUN dnf remove -y npm nodejs nodejs-libs nodejs-docs nodejs-full-i18n \
    python3-requests python3-setuptools \
    && dnf clean all
USER 1001

COPY --from=builder --chown=1001:0 /tmp/wheels /tmp/wheels
COPY requirements.txt .

USER 1001
RUN pip install --no-cache-dir --upgrade setuptools==84.2.1
RUN pip install --no-cache-dir --no-index --find-links=/tmp/wheels -r requirements.txt \
    && rm -rf /tmp/wheels

COPY . .

EXPOSE 5001

CMD ["python3", "app.py"]
