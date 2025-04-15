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

# 3. Set up environment variables
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

# 4. Set up Nginx
echo "Configuring Nginx..."

# Create Nginx configuration
sudo tee /etc/nginx/conf.d/fullstack-auth-app.conf > /dev/null << EOF
# Update this section in your deploy.sh file
server {
    listen 80;
    server_name _;

    location / {
        root $(pwd)/client/dist;  # Make sure this matches your build output directory
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5001;  # Updated to match your server port
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

# 5. Install project dependencies
echo "Installing project dependencies..."
npm run install-all

# 6. Build the client application
echo "Building React client..."
cd client
npm run build
cd ..

# 7. Start the application with PM2
echo "Starting application with PM2..."
pm2 describe auth-api > /dev/null 2>&1 || pm2 start server/index.js --name auth-api -- --port 5001

# Configure PM2 to start on system boot
pm2 startup
pm2 save

# 8. Set up SSL with Let's Encrypt (optional)
read -p "Do you want to set up SSL with Let's Encrypt? (y/n): " setup_ssl
if [ "$setup_ssl" = "y" ]; then
    echo "Setting up SSL with Let's Encrypt..."
    sudo dnf install -y certbot python3-certbot-nginx
    read -p "Enter your domain name: " domain_name
    sudo certbot --nginx -d $domain_name -d www.$domain_name
fi

# 9. Configure security groups (instead of local firewall)
echo "Configuring security groups..."
echo "Please ensure your EC2 security group allows inbound traffic on:"
echo "- Port 22 (SSH)"
echo "- Port 80 (HTTP)"
echo "- Port 443 (HTTPS, if SSL is enabled)"
echo ""
echo "You can configure these in the AWS Management Console:"
echo "1. Go to EC2 Dashboard"
echo "2. Click on 'Security Groups'"
echo "3. Select your instance's security group"
echo "4. Click 'Edit inbound rules'"
echo "5. Add the following rules:"
echo "   - Type: SSH, Port: 22, Source: Your IP"
echo "   - Type: HTTP, Port: 80, Source: 0.0.0.0/0"
echo "   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0 (if SSL is enabled)"

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