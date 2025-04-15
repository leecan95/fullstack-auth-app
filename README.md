# Fullstack Authentication App

A complete authentication system with signup, login, and profile management using React, Express, and PostgreSQL.

## Features

- User registration with bcrypt password hashing
- User login with JWT authentication
- Protected routes and user profile
- PostgreSQL database integration
- Responsive UI with Bootstrap

## Project Structure

- `client`: React frontend
- `server`: Express backend

## Setup Instructions

### Prerequisites

- Node.js
- PostgreSQL database

### Quick Setup

1. Install all dependencies:

```bash
npm run install-all
```

2. Set up the PostgreSQL database:

```bash
npm run db:setup
```
Note: You may need to modify the database.sql file or the connection parameters in server/.env to match your PostgreSQL setup.

3. Start both the client and server:

```bash
npm start
```

The React app will run on port 3000, and the server will run on port 5000.

### Manual Setup

If you prefer to set up each part separately:

#### Database Setup

1. Log into PostgreSQL and create the database and tables:

```bash
psql -U postgres -f server/database.sql
```

#### Backend Setup

1. Navigate to the server directory and install dependencies:

```bash
cd server
npm install
```

2. Configure environment variables (modify .env file as needed).

3. Start the server:

```bash
npm run dev
```

#### Frontend Setup

1. Navigate to the client directory and install dependencies:

```bash
cd client
npm install
```

2. Start the development server:

```bash
npm start
```

## AWS EC2 Deployment

### Option 1: Automated Deployment

1. Launch an EC2 instance (Ubuntu Server recommended)
2. Configure security groups to allow traffic on ports 22, 80, 443, and 5000
3. Connect to your EC2 instance via SSH
4. Clone this repository on your EC2 instance
5. Make the deployment script executable and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual Deployment

For detailed step-by-step instructions on deploying to AWS EC2, see [deploy-ec2.md](deploy-ec2.md).

## API Endpoints

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login a user
- `GET /api/auth/profile` - Get user profile (protected)

## Technologies Used

- **Frontend**: React, React Router, Axios, Bootstrap
- **Backend**: Express, JWT, bcrypt
- **Database**: PostgreSQL 