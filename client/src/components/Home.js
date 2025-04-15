import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Home = () => {
  const { isAuthenticated, currentUser } = useAuth();

  return (
    <div className="home-container">
      {/* Hero Section */}
      <section className="hero-section py-5">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-6">
              <h1 className="display-4 fw-bold mb-4">Welcome to Auth App</h1>
              <p className="lead mb-4">Secure, fast, and reliable authentication system for your needs.</p>
              {isAuthenticated ? (
                <div>
                  <h2 className="h4 mb-3">Hello, {currentUser?.username}!</h2>
                  <Link to="/profile" className="btn btn-primary btn-lg">View Profile</Link>
                </div>
              ) : (
                <div className="d-flex gap-3">
                  <Link to="/login" className="btn btn-primary btn-lg px-4">Login</Link>
                  <Link to="/register" className="btn btn-outline-primary btn-lg px-4">Register</Link>
                </div>
              )}
            </div>
            <div className="col-lg-6">
              <div className="hero-image">
                <img 
                  src="/images/auth-hero.svg" 
                  alt="Authentication Illustration" 
                  className="img-fluid"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="features-section py-5 bg-light">
        <div className="container">
          <h2 className="text-center mb-5">Why Choose Our Auth System?</h2>
          <div className="row g-4">
            <div className="col-md-4">
              <div className="feature-card p-4 text-center">
                <div className="feature-icon mb-3">
                  <i className="fas fa-shield-alt fa-3x text-primary"></i>
                </div>
                <h3 className="h4 mb-3">Secure</h3>
                <p>Advanced security measures to protect your data and privacy.</p>
              </div>
            </div>
            <div className="col-md-4">
              <div className="feature-card p-4 text-center">
                <div className="feature-icon mb-3">
                  <i className="fas fa-bolt fa-3x text-primary"></i>
                </div>
                <h3 className="h4 mb-3">Fast</h3>
                <p>Lightning-fast authentication process with minimal latency.</p>
              </div>
            </div>
            <div className="col-md-4">
              <div className="feature-card p-4 text-center">
                <div className="feature-icon mb-3">
                  <i className="fas fa-sync fa-3x text-primary"></i>
                </div>
                <h3 className="h4 mb-3">Reliable</h3>
                <p>99.9% uptime guarantee with robust backup systems.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      {!isAuthenticated && (
        <section className="cta-section py-5">
          <div className="container text-center">
            <h2 className="mb-4">Ready to Get Started?</h2>
            <p className="lead mb-4">Join thousands of users who trust our authentication system.</p>
            <div className="d-flex justify-content-center gap-3">
              <Link to="/register" className="btn btn-primary btn-lg px-5">Sign Up Now</Link>
              <Link to="/login" className="btn btn-light btn-lg px-5">Login</Link>
            </div>
          </div>
        </section>
      )}
    </div>
  );
};

export default Home; 