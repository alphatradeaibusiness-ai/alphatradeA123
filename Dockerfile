# Render builds the site from the zip in this repository (upload-from-phone setup).
FROM node:22-alpine AS unpack
RUN apk add --no-cache unzip
COPY gotriva-v415-frontend.zip /site.zip
RUN mkdir /app-src && unzip -q /site.zip -d /app-src

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=unpack /app-src/ ./
RUN npm ci
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_AUTH_GOOGLE_ENABLED
ARG VITE_AUTH_APPLE_ENABLED
# v350: public site settings from Render (not secrets) must be build args too, or the site never sees them.
ARG VITE_ADMIN_EMAILS
ARG VITE_CONTACT_EMAIL
ARG VITE_BUSINESS_NAME
ARG VITE_PAY_LINK_MONTHLY
ARG VITE_PAY_LINK_3M
ARG VITE_PAY_LINK_6M
ARG VITE_PAY_LINK_12M
ARG VITE_PAY_LINK_CHANNEL
ARG VITE_PAY_LINK_APEX
ARG VITE_PAY_LINK_MAX
ARG VITE_PAY_LINK_PRIME
ARG VITE_PAY_LINK_SIGNALS_25
ARG VITE_PAY_LINK_SIGNALS_50
ARG VITE_PAY_LINK_SIGNALS_100
ARG VITE_AI_API_URL
ARG VITE_AI_HEALTH_URL
ARG VITE_BINANCE_BASE_URL
ARG VITE_BINANCE_FUTURES_URL
ARG VITE_BINANCE_WS_URL
ARG VITE_BUSINESS_ADDRESS
ARG VITE_BUSINESS_COUNTRY
ARG VITE_DEFAULT_PLAN
ARG VITE_ENFORCE_PLANS
ARG VITE_MARKET_MODE
ARG VITE_MARKET_REFRESH_SECONDS
ARG VITE_MARKET_STREAMING
ARG VITE_REFUND_DAYS
ARG VITE_TD_SYMBOL_SPX500
ARG VITE_TD_SYMBOL_US100
ARG VITE_TD_SYMBOL_US30
ARG VITE_TWELVEDATA_BASE_URL
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/src ./src
COPY --from=build /app/server ./server
COPY --from=build /app/package.json ./
RUN mkdir -p /app/server-data && chown -R node:node /app/server-data
# v276: start as root only until server/dropPrivileges.js hands the data folders (even a root-owned Render disk) to "node", then run as "node"
ENV RUN_AS_USER=node
ENV NODE_ENV=production SERVER_PORT=8787
EXPOSE 8787
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8787/api/health || exit 1
CMD ["node","server/index.js","--serve-dist"]
