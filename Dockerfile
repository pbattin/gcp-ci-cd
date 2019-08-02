# Base Image
FROM node:12.7.0-alpine as build-step

# Installs latest Chromium package.
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
  && echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories \
  && apk add --no-cache \
  chromium@edge \
  harfbuzz@edge \
  nss@edge \
  freetype@edge \
  ttf-freefont@edge \
  && rm -rf /var/cache/* \
  && mkdir /var/cache/apk

# Add Chrome as a user
RUN mkdir -p /usr/src/app \
  && adduser -D chrome \
  && chown -R chrome:chrome /usr/src/app

# Add Enviornment varaible for test
ENV CHROME_BIN=/usr/bin/chromium-browser

# Set our work directory as /app
WORKDIR /app

# Copy package.json to /app
COPY package.json ./

# Install NPM packages from package.json
RUN npm install

# Copy everything from /src folder into the /app working directory of the image
COPY . .

# Now that /src is in the /app working directory, we can build the Angular app and then run test
RUN npm run build &&\
  npm run test

# Setup web server
FROM nginx:1.17.2-alpine as prod-stage

# Copy the dist folder that was built by ng build and place it into the html folder our the nginx server, since thats where the default html for nginx lives
COPY --from=build-step /app/dist/gcp-ci-cd /usr/share/nginx/html

# Expose a port so we can interact with the app
EXPOSE 80

# Need to run some commands so it runs when the image is ran
CMD ["nginx", "-g", "daemon off;"]
