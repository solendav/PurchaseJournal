FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src
RUN mkdir -p uploads/receipts
ENV NODE_ENV=production
EXPOSE 5003
CMD ["node", "src/index.js"]
