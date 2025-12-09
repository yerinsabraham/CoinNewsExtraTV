import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import PrivateRoute from './components/auth/PrivateRoute';

// Pages
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import HomePage from './pages/HomePage';
import VideosPage from './pages/videos/VideosPage';
import VideoDetailPage from './pages/videos/VideoDetailPage';
import QuizListPage from './pages/quiz/QuizListPage';
import QuizPlayPage from './pages/quiz/QuizPlayPage';
import SpinPage from './pages/spin/SpinPage';
import CheckinPage from './pages/checkin/CheckinPage';
import ChatPage from './pages/chat/ChatPage';
import MarketPage from './pages/market/MarketPage';
import ReferralPage from './pages/referral/ReferralPage';
import WalletPage from './pages/wallet/WalletPage';
import ProfilePage from './pages/profile/ProfilePage';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
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

          {/* Redirect unknown routes to home */}
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
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
