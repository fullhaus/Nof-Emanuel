# Multi-stage builds: https://docs.docker.com/develop/develop-images/multistage-build/

# for build
FROM public.ecr.aws/docker/library/node:23.3.0-alpine AS build
# https://stackoverflow.com/questions/65806330/toomanyrequests-you-have-reached-your-pull-rate-limit-you-may-increase-the-lim
# FROM node:23.3.0-alpine
ENV app=/usr/src/app
WORKDIR ${app}
COPY package.json yarn.lock app.js  ./
RUN yarn install

# for production
FROM public.ecr.aws/docker/library/node:23.3.0-alpine
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/ ./
EXPOSE 3000
ENTRYPOINT ["node","./app.js"]
