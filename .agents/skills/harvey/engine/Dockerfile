FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# System deps (curl needed for the Claude CLI installer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python deps first (cached layer — rebuilds only when requirements change),
# then Chromium + its system libraries in the same layer cleanup pass.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && playwright install --with-deps chromium \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Match the checkout owner on Linux; remain non-root.
ARG HARVEY_UID=1000
ARG HARVEY_GID=1000
RUN test "$HARVEY_UID" -gt 0 && test "$HARVEY_GID" -gt 0 \
    && groupadd --gid "$HARVEY_GID" harvey \
    && useradd --create-home --uid "$HARVEY_UID" --gid "$HARVEY_GID" harvey \
    && mkdir -p /app/data \
    && chown -R harvey:harvey /app /ms-playwright

# Copy project (config/prompts are typically bind-mounted over these at runtime)
COPY --chown=harvey:harvey harvey/ harvey/
COPY --chown=harvey:harvey prompts/ prompts/
COPY --chown=harvey:harvey skills/ skills/
COPY --chown=harvey:harvey harvey.yaml .

USER harvey
ENV PATH="/home/harvey/.local/bin:${PATH}"

# Claude Code CLI, installed as the runtime user so ~/.local/bin is correct.
# Download separately so fetch failures cannot be hidden by a shell pipeline.
# Fail the build if installation or Harvey's CLI isolation check fails.
RUN installer="$(mktemp)" \
    && curl -fsSL https://claude.ai/install.sh -o "$installer" \
    && bash "$installer" \
    && rm "$installer" \
    && python -c "from harvey.claude_runtime import check_cli; print(check_cli())"

# Healthy = the dashboard is accepting connections on its loopback port. The
# heartbeat loop is started from the dashboard on demand, so database activity
# is not a reliable liveness signal for the container's main process.
HEALTHCHECK --interval=1m --timeout=10s --start-period=1m --retries=3 \
  CMD python -c "import socket; socket.create_connection(('127.0.0.1', 5555), timeout=5).close()"

# WebUI first: `docker run` serves the dashboard; it starts/stops the
# heartbeat loop itself. Any arguments replace the default command, so
# `docker compose run --rm harvey setup` runs the setup wizard.
ENTRYPOINT ["python", "-m", "harvey"]
CMD ["dashboard"]
