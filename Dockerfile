# --------------> The installer image
FROM bingtsingw/node-alpine:16-pnpm AS installer

WORKDIR /app

COPY pnpm-lock.yaml .
RUN pnpm fetch --prod
COPY package.json .
RUN pnpm install -r --offline --prod --frozen-lockfile

# --------------> The builder image
FROM bingtsingw/node-alpine:16-pnpm AS builder

WORKDIR /app

COPY pnpm-lock.yaml .
RUN pnpm fetch
COPY package.json .
RUN pnpm install -r --offline

COPY . .
RUN pnpm build

# --------------> The base image
FROM bingtsingw/node-alpine:16-slim AS base

RUN apk add --no-cache tini

USER node
ENV NO_COLOR true
WORKDIR /usr/src/app

COPY --chown=node:node --from=installer /app/node_modules node_modules
COPY --chown=node:node --from=builder /app/dist dist

# --------------> The development image
FROM base AS development

USER node
ENV NODE_ENV development

WORKDIR /usr/src/app

CMD ["/sbin/tini", "node", "dist/main"]

# --------------> The production image
FROM base AS production

USER node
ENV NODE_ENV production

WORKDIR /usr/src/app

CMD ["/sbin/tini", "node", "dist/main"]
