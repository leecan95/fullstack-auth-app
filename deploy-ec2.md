# Deploying to AWS EC2

## Prerequisites
- AWS account
- EC2 instance running (Amazon Linux 2 or Ubuntu recommended)
- Domain name (optional)

## Step 1: Launch an EC2 Instance

1. Log in to your AWS Management Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Choose an Amazon Machine Image (AMI) - Ubuntu Server 20.04 LTS recommended
5. Choose an instance type (t2.micro is eligible for free tier)
6. Configure Security Groups:
   - Allow SSH (Port 22)
   - Allow HTTP (Port 80)
   - Allow HTTPS (Port 443)
   - Allow custom TCP for your application ports (3000, 5000)
7. Launch the instance and create/select a key pair

## Step 2: Connect to Your EC2 Instance

```bash
ssh -i /path/to/your-key.pem ec2-user@your-ec2-public-dns
# or for Ubuntu
ssh -i /path/to/your-key.pem ubuntu@your-ec2-public-dns
```

## Step 3: Install Dependencies

```bash
# Update package lists
sudo apt update
sudo apt upgrade -y

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Git
sudo apt install -y git

# Install PM2 globally
sudo npm install -g pm2
```

## Step 4: Configure PostgreSQL

```bash
# Switch to postgres user
sudo -i -u postgres

# Create a database user
createuser --interactive
# Enter name of role to add: authapp
# Shall the new role be a superuser? (y/n): y

# Create database
createdb auth_db

# Access PostgreSQL shell
psql

# Set password for the user
ALTER USER authapp WITH PASSWORD 'your_secure_password';

# Exit PostgreSQL shell
\q

# Exit postgres user session
exit
```

## Step 5: Clone and Set Up Your Project

```bash
# Clone your repository
git clone https://github.com/yourusername/fullstack-auth-app.git
cd fullstack-auth-app

# Install dependencies
npm run install-all

# Create and edit .env file
nano server/.env
```

Add the following to the server/.env file (modify as needed):
```
PORT=5000
DB_USER=authapp
DB_PASSWORD=your_secure_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=auth_db
JWT_SECRET=your_jwt_secret_key_change_this_in_production
```

## Step 6: Import Database Schema

```bash
# Copy database.sql to postgres user's home
sudo cp server/database.sql /tmp/
sudo chown postgres:postgres /tmp/database.sql

# Run as postgres user
sudo -u postgres psql -f /tmp/database.sql
```

## Step 7: Build the React App for Production

```bash
# Navigate to client directory
cd client

# Install dependencies if not already done
npm install

# Build the React app
npm run build
```

## Step 8: Set Up Nginx as a Reverse Proxy

```bash
# Install Nginx
sudo apt install -y nginx

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

Create Nginx configuration file:
```bash
sudo nano /etc/nginx/sites-available/fullstack-auth-app
```

Add the following configuration:
```
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    # If you don't have a domain, use your EC2 Public IP

    location / {
        root /home/ubuntu/fullstack-auth-app/client/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site and restart Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/fullstack-auth-app /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remove default site
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## Step 9: Run Your Application with PM2

```bash
# Navigate back to project root
cd ~/fullstack-auth-app

# Start the server with PM2
pm2 start server/index.js --name auth-api

# Make PM2 startup on system boot
pm2 startup
# Run the command PM2 provides

# Save the PM2 configuration
pm2 save
```

## Step 10: Update Client API URLs (if needed)

If your backend URL has changed, update the API endpoints in your client code:

```bash
# Edit the AuthContext.js file to update API URLs
# Change http://localhost:5000 to your domain or EC2 public IP
nano client/src/contexts/AuthContext.js
```

Then rebuild your client application:
```bash
cd client
npm run build
```

## Step 11: Set Up SSL with Let's Encrypt (Optional but Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Follow the prompts
# Choose to redirect HTTP traffic to HTTPS
```

## Troubleshooting

- **Check application logs**: `pm2 logs`
- **Check Nginx logs**: 
  - Access logs: `sudo cat /var/log/nginx/access.log`
  - Error logs: `sudo cat /var/log/nginx/error.log`
- **Check system logs**: `sudo journalctl -u nginx`
- **Restart services**: 
  - `sudo systemctl restart nginx`
  - `pm2 restart all`

## Updating Your Application

```bash
# Pull latest changes
cd ~/fullstack-auth-app
git pull

# Install any new dependencies
npm run install-all

# Rebuild client
cd client
npm run build

# Restart server
pm2 restart auth-api
``` 