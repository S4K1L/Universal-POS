# syntax=docker/dockerfile:1

# Production image for the web app: compile the Flutter release bundle, then serve it with unprivileged nginx.
# The API server is chosen when the container starts, with API_BASE (see docker/nginx/default.conf.template).

# Must ship Dart >= 3.13.2 (pubspec.yaml); Flutter 3.47.0 and 3.47.1 do not.
ARG FLUTTER_VERSION=3.47.8

FROM debian:trixie-slim AS build
ARG FLUTTER_VERSION
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
# pubspec.yaml bundles .env as an asset but it is gitignored and kept out of the build context, so ship an empty one;
# nginx answers assets/.env from the container's environment instead.
# CanvasKit is bundled rather than fetched from Google's CDN, so a till on a shop LAN without internet still loads.
RUN printf 'API_BASE=\n' > .env \
    && flutter build web --release --no-web-resources-cdn \
    && find build/web -type f \( -name '*.js' -o -name '*.wasm' -o -name '*.json' -o -name '*.html' \
        -o -name '*.ttf' -o -name '*.otf' -o -name '*.bin' -o -name '*.symbols' -o -name 'NOTICES' \) \
        -exec gzip -9 -k {} +

FROM nginxinc/nginx-unprivileged:1.30-alpine
# Always defined, so an unset API_BASE renders as empty (the app then uses the page's host on port 8000)
# rather than a literal "${API_BASE}". The filter keeps envsubst away from nginx's own $variables.
ENV API_BASE="" \
    NGINX_ENVSUBST_FILTER=API_BASE
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 9001
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:9001/healthz || exit 1
