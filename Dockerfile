# Base Image (Adjust version to App version if needed)
FROM node:14.18.2-alpine as build-step

# TEST DEPENDENCY SET UP STEP

# Need to install chromium to run test
# We copy the repo into a variable named @repo. Then we can reference it for packages by appending @repo
RUN echo @repo http://dl-cdn.alpinelinux.org/alpine/v3.10/main >> /etc/apk/repositories \
    && apk add --no-cache \
    chromium@repo \
    harfbuzz@repo \
    nss@repo \
    freetype@repo \
    ttf-freefont@repo \
    && rm -rf /var/cache/* \
    && mkdir /var/cache/apk

# Add Chrome as a user
RUN mkdir -p /usr/src/app \
    && adduser -D chrome \
    && chown -R chrome:chrome /usr/src/app

# Add Enviornment varaible for test
ENV CHROME_BIN=/usr/bin/chromium-browser

# END TEST DEPENDENCY SET UP STEP

# Set our work directory as /app
WORKDIR /app

# Copy package.json to /app
COPY package.json ./

# Install NPM packages from package.json. May wish to switch to ypm
RUN npm ci

# Copy everything not ignored in the .dockerignore file into the /app working directory of the image
COPY . .

# Now that / is in the /app working directory, we can build the Angular app and then run test
RUN npm run build &&\
    npm run test &&\
    npm run lint

# Setup web server
FROM nginx:1.21.5-alpine as prod-stage

# Copy the dist folder that was built by ng build and place it into the html folder our the nginx server, since thats where the default html for nginx lives
COPY --from=build-step /app/dist/gcp-ci-cd /usr/share/nginx/html

# Expose a port so we can interact with the app (Port 80 is exposed by default, being verbose here)
# We then will need to map the port on the host to the container. Can be done by using the following: docker run -p host:container  container image (ex: docker run -p 4200:80 2ea868de3904)
EXPOSE 80

# Need to run some commands so it runs when the image is ran
CMD ["nginx", "-g", "daemon off;"]
