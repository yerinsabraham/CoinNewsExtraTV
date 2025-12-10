import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { lazy, Suspense } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import PrivateRoute from './components/auth/PrivateRoute';

// Auth pages (not lazy loaded - needed immediately)
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import HomePage from './pages/HomePage';

// Lazy load feature pages
const VideosPage = lazy(() => import('./pages/videos/VideosPage'));
const VideoDetailPage = lazy(() => import('./pages/videos/VideoDetailPage'));
const QuizListPage = lazy(() => import('./pages/quiz/QuizListPage'));
const QuizPlayPage = lazy(() => import('./pages/quiz/QuizPlayPage'));
const SpinPage = lazy(() => import('./pages/spin/SpinPage'));
const CheckinPage = lazy(() => import('./pages/checkin/CheckinPage'));
const ChatPage = lazy(() => import('./pages/chat/ChatPage'));
const MarketPage = lazy(() => import('./pages/market/MarketPage'));
const ReferralPage = lazy(() => import('./pages/referral/ReferralPage'));
const WalletPage = lazy(() => import('./pages/wallet/WalletPage'));
const ProfilePage = lazy(() => import('./pages/profile/ProfilePage'));
const LeaderboardPage = lazy(() => import('./pages/leaderboard/LeaderboardPage'));
const AIAssistantPage = lazy(() => import('./pages/ai/AIAssistantPage'));
const AdminDashboard = lazy(() => import('./pages/admin/AdminDashboard'));
const AccountCreatorPage = lazy(() => import('./pages/admin/AccountCreatorPage'));

// Loading component
const LoadingFallback = () => (
  <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center">
    <div className="text-center">
      <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-blue-500 mx-auto mb-4"></div>
      <p className="text-gray-400">Loading...</p>
    </div>
  </div>
);

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Suspense fallback={<LoadingFallback />}>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
            
            <Route 
              path="/" 
              element={
                <PrivateRoute>
                  <HomePage />
                </PrivateRoute>
              } 
            />

            <Route 
              path="/videos" 
              element={
                <PrivateRoute>
                  <VideosPage />
                </PrivateRoute>
            } 
          />

          <Route 
            path="/videos/:videoId" 
            element={
              <PrivateRoute>
                <VideoDetailPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/quiz" 
            element={
              <PrivateRoute>
                <QuizListPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/quiz/:quizId" 
            element={
              <PrivateRoute>
                <QuizPlayPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/spin" 
            element={
              <PrivateRoute>
                <SpinPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/checkin" 
            element={
              <PrivateRoute>
                <CheckinPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/chat" 
            element={
              <PrivateRoute>
                <ChatPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/market" 
            element={
              <PrivateRoute>
                <MarketPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/referral" 
            element={
              <PrivateRoute>
                <ReferralPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/wallet" 
            element={
              <PrivateRoute>
                <WalletPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/profile" 
            element={
              <PrivateRoute>
                <ProfilePage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/leaderboard" 
            element={
              <PrivateRoute>
                <LeaderboardPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/ai" 
            element={
              <PrivateRoute>
                <AIAssistantPage />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/admin" 
            element={
              <PrivateRoute>
                <AdminDashboard />
              </PrivateRoute>
            } 
          />

          <Route 
            path="/admin/accounts" 
            element={
              <PrivateRoute>
                <AccountCreatorPage />
              </PrivateRoute>
            } 
          />

          {/* Redirect unknown routes to home */}
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
        </Suspense>
      </BrowserRouter>
      
      <Toaster 
        position="top-right"
        toastOptions={{
          duration: 3000,
          style: {
            background: '#1A1A1A',
            color: '#fff',
          },
          success: {
            iconTheme: {
              primary: '#006833',
              secondary: '#fff',
            },
          },
        }}
      />
    </AuthProvider>
  );
}

export default App;
