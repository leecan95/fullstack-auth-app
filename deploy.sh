#!/bin/bash

# Exit on any error
set -e

echo "Deploying Fullstack Auth App to AWS EC2..."

# 1. Update system packages
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# 2. Install required software
echo "Installing required software..."

# Install Node.js 18.x (LTS)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install PostgreSQL 15
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL 15..."
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt update
    sudo apt install -y postgresql-15 postgresql-contrib
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt install -y nginx
fi

# Install PM2 globally
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# Install Git if not present
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt install -y git
fi

# 3. Set up PostgreSQL
echo "Setting up PostgreSQL..."

# Create database and user if they don't exist
if ! sudo -u postgres psql -lqt | grep -q auth_db; then
    echo "Creating database and user..."
    sudo -u postgres createuser --superuser authapp || true
    sudo -u postgres createdb auth_db || true
    sudo -u postgres psql -c "ALTER USER authapp WITH PASSWORD 'cancaucacan';" || true
    
    # Import schema
    sudo cp server/database.sql /tmp/
    sudo chown postgres:postgres /tmp/database.sql
    sudo -u postgres psql -f /tmp/database.sql
fi

# 4. Configure PostgreSQL for remote access
echo "Configuring PostgreSQL for remote access..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/15/main/postgresql.conf
sudo sed -i "s/host    all             all             127.0.0.1\/32            scram-sha-256/host    all             all             0.0.0.0\/0            scram-sha-256/" /etc/postgresql/15/main/pg_hba.conf

# Restart PostgreSQL
sudo systemctl restart postgresql

# 5. Set up Nginx
echo "Configuring Nginx..."

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/fullstack-auth-app > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        root $(pwd)/client/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site and remove default
sudo ln -sf /etc/nginx/sites-available/fullstack-auth-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# 6. Set up environment variables
echo "Setting up environment variables..."
if [ ! -f "server/.env" ]; then
    cat > server/.env << EOF
PORT=5000
DB_USER=authapp
DB_PASSWORD=cancaucacan
DB_HOST=postgre-db.craw4ikasnx6.ap-southeast-2.rds.amazonaws.com
DB_PORT=5432
DB_NAME=auth_db
JWT_SECRET=$(openssl rand -hex 32)
EOF
fi

# 7. Install project dependencies
echo "Installing project dependencies..."
npm run install-all

# 8. Build the client application
echo "Building React client..."
cd client
npm run build
cd ..

# 9. Start the application with PM2
echo "Starting application with PM2..."
pm2 describe auth-api > /dev/null 2>&1 || pm2 start server/index.js --name auth-api

# Configure PM2 to start on system boot
pm2 startup
pm2 save

# 10. Set up SSL with Let's Encrypt (optional)
read -p "Do you want to set up SSL with Let's Encrypt? (y/n): " setup_ssl
if [ "$setup_ssl" = "y" ]; then
    echo "Setting up SSL with Let's Encrypt..."
    sudo apt install -y certbot python3-certbot-nginx
    read -p "Enter your domain name: " domain_name
    sudo certbot --nginx -d $domain_name -d www.$domain_name
fi

# 11. Configure firewall
echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "Deployment complete!"
echo "Your application should be running at:"
echo "HTTP: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
if [ "$setup_ssl" = "y" ]; then
    echo "HTTPS: https://$domain_name"
fi

echo "To monitor your application:"
echo "1. Check logs: pm2 logs auth-api"
echo "2. Check status: pm2 status"
echo "3. Restart if needed: pm2 restart auth-api" 