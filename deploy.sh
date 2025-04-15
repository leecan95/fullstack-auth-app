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
# Update the PORT in the environment variables section
if [ ! -f "server/.env" ]; then
    cat > server/.env << EOF
PORT=5001
DB_USER=authapp
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
# Update your Nginx configuration section
sudo tee /etc/nginx/conf.d/fullstack-auth-app.conf > /dev/null << EOF
server {
    listen 80;
    server_name _;

    # Add error logging
    error_log /var/log/nginx/fullstack-app-error.log debug;
    access_log /var/log/nginx/fullstack-app-access.log;

    # Add this line to handle favicon.ico requests
    location = /favicon.ico {
        access_log off;
        log_not_found off;
        return 204;
    }

    location / {
        root /home/ec2-user/first-app/fullstack-auth-app/client/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        # Add proper permissions
        add_header 'Access-Control-Allow-Origin' '*';
    }

    location /api {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        # Add timeout settings
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
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
# Check if dist directory exists, if not, create it and copy from build
if [ ! -d "dist" ]; then
  mkdir -p dist
  if [ -d "build" ]; then
    cp -r build/* dist/
  fi
fi
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

# After building the client application and copying files to dist
echo "Setting proper file permissions..."
sudo chmod -R 755 /home/ec2-user/first-app/fullstack-auth-app/client/dist
sudo chown -R nginx:nginx /home/ec2-user/first-app/fullstack-auth-app/client/dist
# Add after setting permissions
echo "Setting SELinux context if needed..."
if command -v getenforce &> /dev/null; then
    if [ "$(getenforce)" = "Enforcing" ]; then
        sudo chcon -Rt httpd_sys_content_t /home/ec2-user/first-app/fullstack-auth-app/client/dist
    fi
fi

# Add after starting the application with PM2
echo "Checking application status..."
pm2 status
echo "Checking if server is listening on port 5001..."
netstat -tulpn | grep 5001 || echo "Server not listening on port 5001"
echo "Checking Nginx configuration..."
sudo nginx -t
echo "Checking Nginx status..."
sudo systemctl status nginx