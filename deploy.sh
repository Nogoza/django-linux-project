#!/bin/bash

set -e 



echo "Deployment"



echo "Kodlar çekiliyor"

git pull origin main



echo "sanal ortam aktif ediliyor"

# Eğer sanal ortam klasörünün adı venv değilse burayı güncelle

source venv/bin/activate



echo "Gereksinimler yükleniyor..."

pip install -r requirements.txt



echo "Veritabanı migration işlemleri yapılıyor."

python manage.py migrate



echo "Statik dosyalar toplanıyor."

python manage.py collectstatic --noinput



echo "Gunicorn yeniden başlatılıyor."

pkill gunicorn || true 



gunicorn core.wsgi:application --bind 127.0.0.1:8000 --daemon



echo "Deployment tamamlandı!"

