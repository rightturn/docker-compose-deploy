FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /srv/app
COPY app/package.json ./
COPY app/server.js ./

# run as the unprivileged "node" user that ships with the image
USER node
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "server.js"]
