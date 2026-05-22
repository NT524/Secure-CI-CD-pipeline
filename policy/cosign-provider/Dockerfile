FROM python:3.12-slim

ARG COSIGN_VERSION=v2.4.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/cosign "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64" \
    && chmod +x /usr/local/bin/cosign

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8090

CMD ["python3", "/app/app.py"]
