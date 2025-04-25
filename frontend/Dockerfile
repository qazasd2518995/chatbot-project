# ---------- Build stage ----------
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build          # Vite 產物在 dist/，CRA 在 build/

# ---------- Runtime stage ----------
FROM nginx:1.27-alpine
# 如果你是 CRA → build；Vite → dist
COPY --from=builder /app/build /usr/share/nginx/html
#   ↑ 若你用 Vite，請把 build 改成 dist
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
