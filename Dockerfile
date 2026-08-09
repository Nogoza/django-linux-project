# ==========================================
# 1. AŞAMA: frontend-builder (JS Derleme)
# ==========================================
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend

# Sahte package.json dosyasını içeri kopyalıyoruz
COPY frontend/package.json ./

# dist/bundle.js dosyasının üretilmesini sağlıyoruz
RUN npm run build


# ==========================================
# 2. AŞAMA: backend-builder (Python Paketlerini Derleme)
# ==========================================
FROM python:3.11-alpine AS backend-builder
WORKDIR /usr/src/app

# Ağır derleyicileri kuruyoruz (Final imajına geçmeyecek)
RUN apk add --no-cache gcc musl-dev postgresql-dev libffi-dev

COPY requirements.txt ./

# Paketleri kurmak yerine, taşınabilir "tekerlekler" (wheel) olarak derliyoruz
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


# ==========================================
# 3. AŞAMA: runtime (Temiz ve Güvenli Çalışma Ortamı)
# ==========================================
FROM python:3.11-alpine
WORKDIR /app

# Sadece uygulamanın çalışması için gereken hafif kütüphaneleri kuruyoruz (gcc YOK)
RUN apk add --no-cache libpq libffi

# 1. Kritik Nokta: Python tekerleklerini backend-builder'dan çek ve yerel olarak kur
COPY --from=backend-builder /usr/src/app/wheels /wheels
RUN pip install --no-cache /wheels/*

# 2. Kritik Nokta: React statik dosyalarını frontend-builder'dan çek
COPY --from=frontend-builder /app/frontend/dist /app/static

# Kalan proje kodlarını kopyala
COPY . .

# Güvenli (non-root) kullanıcı ayarları
RUN adduser -D django-user && \
    chown -R django-user:django-user /app
USER django-user

# Gunicorn ile uygulamayı başlat
CMD ["sh", "-c", "python manage.py collectstatic --noinput && python manage.py migrate && gunicorn --bind 0.0.0.0:8000 core.wsgi:application"]