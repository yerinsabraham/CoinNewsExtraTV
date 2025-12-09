import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { signOut } from 'firebase/auth';
import { auth } from '../../services/firebase';
import { ArrowLeft, User as UserIcon, Mail, Calendar, LogOut, Shield, Bell, Globe } from 'lucide-react';
import toast from 'react-hot-toast';

/**
 * ProfilePage - User profile and settings
 */
const ProfilePage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [loggingOut, setLoggingOut] = useState(false);
  
  const handleLogout = async () => {
    try {
      setLoggingOut(true);
      await signOut(auth);
      toast.success('Logged out successfully');
      navigate('/login');
    } catch (error) {
      console.error('Error logging out:', error);
      toast.error('Failed to log out');
      setLoggingOut(false);
    }
  };
  
  const accountCreated = user?.metadata?.creationTime 
    ? new Date(user.metadata.creationTime).toLocaleDateString()
    : 'Unknown';
  
  const lastSignIn = user?.metadata?.lastSignInTime
    ? new Date(user.metadata.lastSignInTime).toLocaleDateString()
    : 'Unknown';
  
  return (
    <div className="min-h-screen bg-dark-bg pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary to-green-600 text-white p-6">
        <div className="max-w-7xl mx-auto">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-2 text-white/90 hover:text-white mb-4 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Back to Home
          </button>
          
          <div>
            <h1 className="text-3xl font-bold flex items-center gap-3">
              <UserIcon className="w-8 h-8" />
              My Profile
            </h1>
            <p className="text-white/90 mt-2">Manage your account settings</p>
          </div>
        </div>
      </div>
      
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Profile Card */}
        <div className="bg-dark-card rounded-lg p-8 mb-6">
          <div className="flex items-center gap-6 mb-6">
            {user?.photoURL ? (
              <img
                src={user.photoURL}
                alt={user.displayName}
                className="w-24 h-24 rounded-full object-cover border-4 border-primary"
              />
            ) : (
              <div className="w-24 h-24 rounded-full bg-primary flex items-center justify-center text-white text-4xl font-bold border-4 border-primary">
                {user?.displayName?.[0]?.toUpperCase() || user?.email?.[0]?.toUpperCase() || '?'}
              </div>
            )}
            
            <div className="flex-1">
              <h2 className="text-3xl font-bold text-white mb-2">
                {user?.displayName || 'User'}
              </h2>
              <p className="text-gray-400 flex items-center gap-2">
                <Mail className="w-4 h-4" />
                {user?.email}
              </p>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-dark-bg rounded-lg p-4">
              <p className="text-sm text-gray-400 mb-1">Account Created</p>
              <p className="text-white font-semibold flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                {accountCreated}
              </p>
            </div>
            
            <div className="bg-dark-bg rounded-lg p-4">
              <p className="text-sm text-gray-400 mb-1">Last Sign In</p>
              <p className="text-white font-semibold flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                {lastSignIn}
              </p>
            </div>
          </div>
        </div>
        
        {/* Settings Sections */}
        <div className="space-y-4">
          {/* Account Settings */}
          <div className="bg-dark-card rounded-lg p-6">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Shield className="w-5 h-5" />
              Account Settings
            </h3>
            
            <div className="space-y-3">
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors">
                <p className="font-semibold text-white mb-1">Change Password</p>
                <p className="text-sm text-gray-400">Update your password</p>
              </button>
              
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors">
                <p className="font-semibold text-white mb-1">Two-Factor Authentication</p>
                <p className="text-sm text-gray-400">Add an extra layer of security</p>
              </button>
              
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors">
                <p className="font-semibold text-white mb-1">Email Preferences</p>
                <p className="text-sm text-gray-400">Manage email notifications</p>
              </button>
            </div>
          </div>
          
          {/* Preferences */}
          <div className="bg-dark-card rounded-lg p-6">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Bell className="w-5 h-5" />
              Preferences
            </h3>
            
            <div className="space-y-3">
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors">
                <p className="font-semibold text-white mb-1">Notifications</p>
                <p className="text-sm text-gray-400">Configure push notifications</p>
              </button>
              
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors flex items-center justify-between">
                <div>
                  <p className="font-semibold text-white mb-1">Language</p>
                  <p className="text-sm text-gray-400">English (US)</p>
                </div>
                <Globe className="w-5 h-5 text-gray-400" />
              </button>
              
              <button className="w-full text-left p-4 bg-dark-bg hover:bg-dark-bg/80 rounded-lg transition-colors">
                <p className="font-semibold text-white mb-1">Theme</p>
                <p className="text-sm text-gray-400">Dark mode (default)</p>
              </button>
            </div>
          </div>
          
          {/* Danger Zone */}
          <div className="bg-dark-card rounded-lg p-6 border-2 border-red-500/20">
            <h3 className="text-xl font-bold text-red-400 mb-4">Danger Zone</h3>
            
            <div className="space-y-3">
              <button 
                onClick={handleLogout}
                disabled={loggingOut}
                className="w-full text-left p-4 bg-red-500/10 hover:bg-red-500/20 rounded-lg transition-colors border border-red-500/30 flex items-center justify-between"
              >
                <div>
                  <p className="font-semibold text-red-400 mb-1">Log Out</p>
                  <p className="text-sm text-gray-400">Sign out of your account</p>
                </div>
                <LogOut className={`w-5 h-5 text-red-400 ${loggingOut ? 'animate-spin' : ''}`} />
              </button>
              
              <button className="w-full text-left p-4 bg-red-500/10 hover:bg-red-500/20 rounded-lg transition-colors border border-red-500/30">
                <p className="font-semibold text-red-400 mb-1">Delete Account</p>
                <p className="text-sm text-gray-400">Permanently delete your account and data</p>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
