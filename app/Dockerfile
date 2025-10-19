FROM node:20-alpine
WORKDIR /app

# copy only package manifests first
COPY package.json package-lock.json* ./

# If lockfile exists → npm ci; else → npm install
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm install --omit=dev; \
    fi

# now copy the rest of the code
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["npm","start"]

