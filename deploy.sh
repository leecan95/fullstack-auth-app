#!/bin/bash

# Exit on any error
set -e

echo "Deploying Fullstack Auth App to AWS EC2..."

# 1. Update system packages
echo "Updating system packages..."
sudo dnf update -y

# 2. Install required software
echo "Installing required software..."

# Install Node.js 18.x (LTS)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18.x..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo dnf install -y nodejs
fi

# Install PostgreSQL 15
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL 15..."
    sudo dnf install -y postgresql15 postgresql15-server postgresql15-contrib
    sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
    sudo systemctl enable postgresql-15
    sudo systemctl start postgresql-15
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo dnf install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
fi

# Install PM2 globally
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# Install Git if not present
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo dnf install -y git
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
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/15/data/postgresql.conf
sudo sed -i "s/host    all             all             127.0.0.1\/32            scram-sha-256/host    all             all             0.0.0.0\/0            scram-sha-256/" /var/lib/pgsql/15/data/pg_hba.conf

# Restart PostgreSQL
sudo systemctl restart postgresql-15

# 5. Set up Nginx
echo "Configuring Nginx..."

# Create Nginx configuration
sudo tee /etc/nginx/conf.d/fullstack-auth-app.conf > /dev/null << EOF
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

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# 6. Set up environment variables
echo "Setting up environment variables..."
if [ ! -f "server/.env" ]; then
    cat > server/.env << EOF
PORT=5000
DB_USER=postgres
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
    sudo dnf install -y certbot python3-certbot-nginx
    read -p "Enter your domain name: " domain_name
    sudo certbot --nginx -d $domain_name -d www.$domain_name
fi

# 11. Configure firewall
echo "Configuring firewall..."
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

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