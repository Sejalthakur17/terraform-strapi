#!/bin/bash

cat << 'EOF' > /usr/local/bin/strapi-bootstrap.sh
#!/bin/bash

LOG="/var/log/strapi-bootstrap.log"
exec >> $LOG 2>&1

# Check internet
ping -c 1 google.com || exit 0

apt update -y
apt install -y curl git build-essential

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g pm2

cd /home/ubuntu

if [ ! -d "strapi" ]; then
  npx create-strapi-app@latest strapi --quickstart --no-run
fi

cd strapi
npm install
pm2 start npm --name strapi -- run develop -- --host=0.0.0.0
pm2 save

# Disable cron after success
crontab -r
EOF

chmod +x /usr/local/bin/strapi-bootstrap.sh

# Run every 2 minutes
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/local/bin/strapi-bootstrap.sh") | crontab -
