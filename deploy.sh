#!/bin/bash

# Exit on any error
set -e

echo "Deploying Fullstack Auth App to EC2..."

# 1. Update system packages
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# 2. Install required software if not installed
echo "Installing required software..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs
fi

if ! command -v psql &> /dev/null; then
    sudo apt install -y postgresql postgresql-contrib
fi

if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
fi

if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# 3. Set up database (if not already set up)
echo "Setting up database..."
if sudo -u postgres psql -lqt | grep -q auth_db; then
    echo "Database already exists, skipping database creation."
else
    echo "Creating database user and database..."
    sudo -u postgres createuser --superuser authapp || true
    sudo -u postgres createdb auth_db || true
    sudo -u postgres psql -c "ALTER USER authapp WITH PASSWORD 'your_secure_password';" || true
    
    # Import schema
    sudo cp server/database.sql /tmp/
    sudo chown postgres:postgres /tmp/database.sql
    sudo -u postgres psql -f /tmp/database.sql
fi

# 4. Install project dependencies
echo "Installing project dependencies..."
npm run install-all

# 5. Configure environment variables
echo "Setting up environment variables..."
if [ ! -f "server/.env" ]; then
    echo "Creating server .env file..."
    cat > server/.env << EOF
PORT=5000
DB_USER=authapp
DB_PASSWORD=your_secure_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=auth_db
JWT_SECRET=$(openssl rand -hex 32)
EOF
fi

# 6. Build the client application
echo "Building React client..."
cd client
npm run build
cd ..

# 7. Set up Nginx configuration
echo "Configuring Nginx..."
if [ ! -f "/etc/nginx/sites-available/fullstack-auth-app" ]; then
    echo "Creating Nginx config file..."
    # Get the EC2 public IP
    EC2_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    
    sudo tee /etc/nginx/sites-available/fullstack-auth-app > /dev/null << EOF
server {
    listen 80;
    server_name $EC2_PUBLIC_IP;

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

    sudo ln -sf /etc/nginx/sites-available/fullstack-auth-app /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t
    sudo systemctl restart nginx
fi

# 8. Start the application with PM2
echo "Starting application with PM2..."
pm2 describe auth-api > /dev/null 2>&1 || pm2 start server/index.js --name auth-api

# Configure PM2 to start on system boot
pm2 startup
pm2 save

echo "Deployment complete! Your application should be running at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Note: You may need to configure your security groups to allow traffic on ports 80, 443, and 5000." 