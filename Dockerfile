ARG FRAPPE_BRANCH=version-15
ARG PYTHON_VERSION=3.11.9
ARG NODE_VERSION=18.20.3

FROM python:${PYTHON_VERSION}-slim-bookworm AS base

# Install system dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    git \
    mariadb-client \
    postgresql-client \
    gettext-base \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    tcl8.6-dev \
    tk8.6-dev \
    python3-tk \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    libpq-dev \
    build-essential \
    cron \
    locales \
    locales-all \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

# Install NodeJS and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install --no-install-recommends -y nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash frappe

# Setup Frappe Bench environment
FROM base AS builder

ARG FRAPPE_BRANCH=version-15

USER frappe
WORKDIR /home/frappe

RUN pip install --user frappe-bench

ENV PATH="/home/frappe/.local/bin:${PATH}"

# Initialize bench
RUN bench init frappe-bench --frappe-branch ${FRAPPE_BRANCH}

WORKDIR /home/frappe/frappe-bench

# Get Apps (ERPNext and Custom App)
RUN bench get-app --branch ${FRAPPE_BRANCH} erpnext \
    && bench get-app --branch main laboratorio https://github.com/juls-dspro/Laboratorio.git

# Build Assets
RUN bench build

# Setup final runtime image
FROM base AS runner

# Install frappe-bench globally in runner to make bench command globally available
RUN pip install frappe-bench

USER frappe
WORKDIR /home/frappe

# Copy bench from builder
COPY --chown=frappe:frappe --from=builder /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 9000

CMD ["bench", "start"]
