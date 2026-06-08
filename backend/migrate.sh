#!/bin/bash
# Quick setup helper — run once after cloning
set -e
cd "$(dirname "$0")"

echo "==> Installing Python dependencies…"
pip install -r requirements.txt

echo "==> Copying .env.example → .env (if not present)…"
[ -f .env ] || cp .env.example .env

echo "==> Running Django migrations…"
python manage.py migrate

echo "==> Creating superuser (skip if already exists)…"
python manage.py shell -c "
from apps.authentication.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@cashewcare.local', 'admin123')
    print('Superuser created: admin / admin123')
else:
    print('Superuser already exists.')
"

echo ""
echo "==> Done! Start services:"
echo "    Backend:   python manage.py runserver 0.0.0.0:8000"
echo "    Dashboard: cd ../dashboard && npm install && npm run dev"
echo "    Frontend:  open frontend/ in Android Studio / VS Code"
