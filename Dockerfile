#syntax=docker/dockerfile:1.2
FROM node:16 as build
WORKDIR /lambda
RUN apt-get update \
        && apt-get install -y zip \
        && rm -rf /var/lib/apt/lists/*

FROM build as webhook
COPY webhook/lambda /lambda
RUN --mount=type=cache,target=/lambda/node_modules,id=webhook \
        yarn install && yarn dist

FROM build as echo
COPY echo/lambda /lambda
RUN --mount=type=cache,target=/lambda/node_modules,id=echo \
        yarn install && yarn dist


FROM scratch as final
COPY --from=echo       /lambda/echo.zip      /echo.zip
COPY --from=webhook    /lambda/webhook.zip   /webhook.zip
