import React from 'react';
import { useAuth } from '../contexts/AuthContext';

const Profile = () => {
  const { currentUser } = useAuth();

  return (
    <div className="profile-container">
      <div className="row justify-content-center">
        <div className="col-md-6">
          <div className="card">
            <div className="card-body">
              <h2 className="text-center mb-4">Profile</h2>
              
              <div className="profile-info">
                <div className="mb-3">
                  <strong>Username:</strong> {currentUser?.username}
                </div>
                <div className="mb-3">
                  <strong>Email:</strong> {currentUser?.email}
                </div>
                <div className="mb-3">
                  <strong>Account ID:</strong> {currentUser?.id}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile; 