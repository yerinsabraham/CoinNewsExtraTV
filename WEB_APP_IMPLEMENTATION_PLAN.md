# CoinNewsExtra TV - Web App Implementation Plan

**Date**: December 9, 2025  
**Estimated Timeline**: 6-8 weeks (full-time development)  
**Approach**: Incremental, feature-by-feature implementation  

---

## 🎯 Implementation Philosophy

### **Phased Approach**
1. ✅ **Phase 1**: Core foundation (auth, routing, layout)
2. ✅ **Phase 2**: Essential earning features (videos, quiz, spin)
3. ✅ **Phase 3**: Social features (chat, AI, community)
4. ✅ **Phase 4**: Advanced features (Play Extra, live streaming)
5. ✅ **Phase 5**: Admin, polish, optimization
6. ✅ **Phase 6**: Testing, deployment, monitoring

### **Development Principles**
- Build incrementally, test frequently
- Mobile-first responsive design
- Reuse Firebase backend (no backend changes)
- Match mobile app UX as closely as possible
- Performance and accessibility throughout

---

## 📋 PHASE 1: Project Setup & Foundation (Week 1)

### **Step 1.1: Initialize React Project**

```bash
# Create new Vite + React project
npm create vite@latest web -- --template react

cd web
npm install

# Install core dependencies
npm install react-router-dom firebase tailwindcss postcss autoprefixer
npm install zustand axios react-hook-form zod
npm install react-icons react-hot-toast framer-motion

# Install dev dependencies
npm install -D prettier eslint
```

### **Step 1.2: Configure Tailwind CSS**

```bash
npx tailwindcss init -p
```

**Edit tailwind.config.js:**
```javascript
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#006833',
          light: '#00B359',
          dark: '#004D26'
        },
        accent: {
          gold: '#FFD700',
          green: '#34C759',
          red: '#FF3B30'
        },
        dark: {
          bg: '#000000',
          card: '#1A1A1A',
          border: '#2A2A2A',
          text: '#CCCCCC'
        }
      },
      fontFamily: {
        lato: ['Lato', 'sans-serif']
      }
    }
  },
  plugins: []
}
```

**Update src/index.css:**
```css
@import url('https://fonts.googleapis.com/css2?family=Lato:wght@400;700;900&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-dark-bg text-white font-lato;
  }
}
```

### **Step 1.3: Set Up Project Structure**

```bash
mkdir -p src/{components,pages,hooks,contexts,services,utils,styles,assets}
mkdir -p src/components/{common,layout,auth,home,videos,quiz,spin,chat,wallet,market,profile,admin}
mkdir -p public/assets/{icons,images,avatars,fonts}
```

### **Step 1.4: Copy Assets from Flutter App**

```bash
# Copy all assets from Flutter to React public folder
# From: assets/
# To: public/assets/

cp -r ../assets/* public/assets/
```

### **Step 1.5: Configure Firebase**

**Create .env file:**
```env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
VITE_FIREBASE_MEASUREMENT_ID=your_measurement_id
```

**Create src/services/firebase.js:**
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore, enableIndexedDbPersistence } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';
import { getAnalytics } from 'firebase/analytics';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app, 'us-central1');
export const analytics = getAnalytics(app);
export const googleProvider = new GoogleAuthProvider();

// Enable offline persistence
enableIndexedDbPersistence(db).catch((err) => {
  if (err.code === 'failed-precondition') {
    console.warn('Multiple tabs open, persistence can only be enabled in one tab at a time.');
  } else if (err.code === 'unimplemented') {
    console.warn('The current browser does not support persistence.');
  }
});
```

### **Step 1.6: Create Auth Context & Store**

**src/contexts/AuthContext.jsx:**
```javascript
import { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../services/firebase';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  );
};
```

**src/stores/balanceStore.js:**
```javascript
import { create } from 'zustand';

export const useBalanceStore = create((set) => ({
  balance: 0,
  totalEarnings: 0,
  lockedBalance: 0,
  unlockedBalance: 0,
  
  setBalance: (data) => set({
    balance: data.totalBalance || 0,
    totalEarnings: data.totalEarnings || 0,
    lockedBalance: data.lockedBalance || 0,
    unlockedBalance: data.unlockedBalance || 0
  }),
  
  addReward: (amount) => set((state) => ({
    balance: state.balance + amount,
    unlockedBalance: state.unlockedBalance + amount,
    totalEarnings: state.totalEarnings + amount
  }))
}));
```

### **Step 1.7: Set Up Routing**

**src/App.jsx:**
```javascript
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import PrivateRoute from './components/auth/PrivateRoute';

// Pages (to be created)
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import HomePage from './pages/HomePage';
import VideosPage from './pages/VideosPage';
// ... other imports

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/signup" element={<SignupPage />} />
          
          <Route path="/" element={<PrivateRoute><HomePage /></PrivateRoute>} />
          <Route path="/videos" element={<PrivateRoute><VideosPage /></PrivateRoute>} />
          {/* More protected routes */}
        </Routes>
      </BrowserRouter>
      <Toaster position="top-right" />
    </AuthProvider>
  );
}

export default App;
```

### **Step 1.8: Create Layout Components**

**src/components/layout/Header.jsx** (with logo, balance, notifications)  
**src/components/layout/Sidebar.jsx** (desktop navigation)  
**src/components/layout/BottomNav.jsx** (mobile navigation)  
**src/components/layout/MainLayout.jsx** (wrapper with header + sidebar)

### **Step 1.9: Test Foundation**

```bash
npm run dev
```

✅ **Deliverables:**
- Project initialized with Vite + React
- Tailwind CSS configured with custom theme
- Firebase connected and initialized
- Auth context and balance store working
- Routing structure in place
- Layout components responsive
- Can navigate to login page

---

## 📋 PHASE 2: Authentication (Week 1)

### **Step 2.1: Create Auth Service**

**src/services/auth.service.js:**
```javascript
import { 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, googleProvider, db } from './firebase';

export const authService = {
  async signInWithEmail(email, password) {
    return await signInWithEmailAndPassword(auth, email, password);
  },

  async signUpWithEmail(email, password, displayName) {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    await updateProfile(userCredential.user, { displayName });
    
    // Create user document in Firestore
    await setDoc(doc(db, 'users', userCredential.user.uid), {
      uid: userCredential.user.uid,
      email: email,
      displayName: displayName,
      cneBalance: 700, // Signup bonus
      totalBalance: 700,
      unlockedBalance: 700,
      lockedBalance: 0,
      totalEarnings: 700,
      referralCode: this.generateReferralCode(userCredential.user.uid),
      createdAt: serverTimestamp()
    });

    return userCredential;
  },

  async signInWithGoogle() {
    const userCredential = await signInWithPopup(auth, googleProvider);
    const isNewUser = userCredential._tokenResponse?.isNewUser;
    
    if (isNewUser) {
      // Create user document for new Google users
      await setDoc(doc(db, 'users', userCredential.user.uid), {
        uid: userCredential.user.uid,
        email: userCredential.user.email,
        displayName: userCredential.user.displayName,
        cneBalance: 700,
        totalBalance: 700,
        unlockedBalance: 700,
        lockedBalance: 0,
        totalEarnings: 700,
        referralCode: this.generateReferralCode(userCredential.user.uid),
        createdAt: serverTimestamp()
      });
    }

    return userCredential;
  },

  async logout() {
    return await signOut(auth);
  },

  generateReferralCode(uid) {
    return uid.substring(0, 8).toUpperCase();
  }
};
```

### **Step 2.2: Create Login Page**

**src/pages/LoginPage.jsx:**
- Email/password form
- Google Sign-In button
- Link to signup page
- Form validation with react-hook-form + zod
- Loading states
- Error handling with toast notifications

### **Step 2.3: Create Signup Page**

**src/pages/SignupPage.jsx:**
- Name, email, password fields
- Optional referral code field
- Google Sign-In option
- Form validation
- Auto-redirect to home after signup

### **Step 2.4: Create PrivateRoute Component**

**src/components/auth/PrivateRoute.jsx:**
```javascript
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const PrivateRoute = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <div className="flex items-center justify-center h-screen">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>;
  }

  return user ? children : <Navigate to="/login" />;
};

export default PrivateRoute;
```

✅ **Deliverables:**
- Login page functional (email + Google)
- Signup page with 700 CNE bonus
- Auto-create Firestore user document
- Protected routes working
- Session persistence

---

## 📋 PHASE 3: Home Dashboard & Balance (Week 2)

### **Step 3.1: Create Balance Service**

**src/services/balance.service.js:**
```javascript
import { doc, onSnapshot, updateDoc, increment } from 'firebase/firestore';
import { db } from './firebase';
import { useBalanceStore } from '../stores/balanceStore';

export const balanceService = {
  subscribeToBalance(userId) {
    const userDoc = doc(db, 'users', userId);
    
    return onSnapshot(userDoc, (snapshot) => {
      if (snapshot.exists()) {
        const data = snapshot.data();
        useBalanceStore.getState().setBalance(data);
      }
    });
  },

  async addReward(userId, amount, type) {
    const userDoc = doc(db, 'users', userId);
    await updateDoc(userDoc, {
      cneBalance: increment(amount),
      totalBalance: increment(amount),
      unlockedBalance: increment(amount),
      totalEarnings: increment(amount),
      lastUpdated: serverTimestamp()
    });

    // Log reward
    await addDoc(collection(db, 'rewards_log'), {
      userId,
      amount,
      type,
      timestamp: serverTimestamp()
    });
  }
};
```

### **Step 3.2: Create Home Page Components**

**Components to build:**
1. **BannerCarousel.jsx** - Hero slider with promotions
2. **QuickFeatures.jsx** - Grid of feature cards (videos, quiz, spin, etc.)
3. **BalanceCard.jsx** - Display CNE balance prominently
4. **RecentActivity.jsx** - Last 5 earning activities

**src/pages/HomePage.jsx:**
- Use MainLayout wrapper
- Display balance at top
- Banner carousel
- Quick feature grid (8-10 features)
- Recent activity feed
- Bottom navigation (mobile)

### **Step 3.3: Create Common Components**

1. **Button.jsx** - Reusable button with variants (primary, secondary, outline)
2. **Card.jsx** - Container with shadow and border
3. **Loader.jsx** - Spinning loader animation
4. **Modal.jsx** - Modal dialog with backdrop

### **Step 3.4: Implement Balance Sync**

**Hook: useBalance.js:**
```javascript
import { useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { balanceService } from '../services/balance.service';
import { useBalanceStore } from '../stores/balanceStore';

export const useBalance = () => {
  const { user } = useAuth();
  const balance = useBalanceStore();

  useEffect(() => {
    if (!user) return;

    const unsubscribe = balanceService.subscribeToBalance(user.uid);
    return unsubscribe;
  }, [user]);

  return balance;
};
```

✅ **Deliverables:**
- Home page with all sections
- Balance displays in real-time
- Quick access to all features
- Responsive layout (mobile + desktop)
- Balance persistence verified

---

## 📋 PHASE 4: Video Library & Watch2Earn (Week 2)

### **Step 4.1: Install Video Dependencies**

```bash
npm install react-youtube react-player
```

### **Step 4.2: Create Video Service**

**src/services/video.service.js:**
```javascript
import { collection, getDocs, doc, getDoc } from 'firebase/firestore';
import { db } from './firebase';

export const videoService = {
  async getAllVideos() {
    const snapshot = await getDocs(collection(db, 'videos'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  },

  async getVideoById(videoId) {
    const docRef = doc(db, 'videos', videoId);
    const snapshot = await getDoc(docRef);
    return snapshot.exists() ? { id: snapshot.id, ...snapshot.data() } : null;
  },

  async markVideoWatched(userId, videoId) {
    const key = `video_watched_${videoId}`;
    localStorage.setItem(key, 'true');
  },

  isVideoWatched(videoId) {
    const key = `video_watched_${videoId}`;
    return localStorage.getItem(key) === 'true';
  }
};
```

### **Step 4.3: Create Video Components**

**src/components/videos/VideoCard.jsx:**
- Thumbnail display
- Video title, duration, views
- Reward badge (7 CNE)
- "Watched" indicator
- Click to play

**src/components/videos/VideoPlayer.jsx:**
```javascript
import YouTube from 'react-youtube';
import { useState, useEffect } from 'react';

const VideoPlayer = ({ videoId, onVideoEnd }) => {
  const [watchTime, setWatchTime] = useState(0);

  const opts = {
    height: '100%',
    width: '100%',
    playerVars: {
      autoplay: 1,
      controls: 1,
      rel: 0
    }
  };

  const handleStateChange = (event) => {
    // Track watch time
    if (event.data === 1) { // Playing
      const interval = setInterval(() => {
        setWatchTime(prev => prev + 1);
      }, 1000);
      return () => clearInterval(interval);
    }
  };

  const handleEnd = () => {
    if (watchTime >= 30) { // Watched for at least 30 seconds
      onVideoEnd();
    }
  };

  return (
    <YouTube
      videoId={videoId}
      opts={opts}
      onStateChange={handleStateChange}
      onEnd={handleEnd}
    />
  );
};
```

### **Step 4.4: Create Videos Page**

**src/pages/VideosPage.jsx:**
- Grid of video cards
- Category filter (Bitcoin, Ethereum, DeFi, etc.)
- Search functionality
- Reward claim modal after watching
- Video player in modal or full screen

### **Step 4.5: Implement Reward Claiming**

**src/services/rewards.service.js:**
```javascript
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';
import toast from 'react-hot-toast';

export const rewardsService = {
  async claimVideoReward(videoId) {
    try {
      const claimReward = httpsCallable(functions, 'claimReward');
      const result = await claimReward({
        type: 'video_watch',
        videoId: videoId,
        amount: 7
      });

      if (result.data.success) {
        toast.success('🎉 Earned 7 CNE!');
        return true;
      }
    } catch (error) {
      toast.error('Failed to claim reward');
      return false;
    }
  }
};
```

✅ **Deliverables:**
- Videos page with grid layout
- YouTube player integration working
- Watch tracking (30+ seconds)
- Reward claiming after video completion
- 7 CNE added to balance
- Watched status persisted

---

## 📋 PHASE 5: Quiz System (Week 3)

### **Step 5.1: Create Quiz Service**

**src/services/quiz.service.js:**
```javascript
import { collection, getDocs, doc, setDoc, getDoc } from 'firebase/firestore';
import { db } from './firebase';

export const quizService = {
  async getQuizCategories() {
    const snapshot = await getDocs(collection(db, 'quizzes'));
    return snapshot.docs.map(doc => doc.id);
  },

  async getQuizQuestions(category) {
    const docRef = doc(db, 'quizzes', category);
    const snapshot = await getDoc(docRef);
    return snapshot.exists() ? snapshot.data().questions : [];
  },

  async saveQuizProgress(userId, category, score, tokensEarned) {
    await setDoc(doc(db, 'quiz_progress', `${userId}_${category}`), {
      userId,
      category,
      score,
      tokensEarned,
      completedAt: serverTimestamp()
    });
  },

  async getQuizProgress(userId, category) {
    const docRef = doc(db, 'quiz_progress', `${userId}_${category}`);
    const snapshot = await getDoc(docRef);
    return snapshot.exists() ? snapshot.data() : null;
  }
};
```

### **Step 5.2: Create Quiz Components**

**Components:**
1. **QuizCategoryCard.jsx** - Category selection cards
2. **QuestionDisplay.jsx** - Question text + 4 options
3. **Timer.jsx** - 15-second countdown
4. **ProgressBar.jsx** - Question progress (1/10)
5. **ScoreDisplay.jsx** - Final score + rewards

### **Step 5.3: Create Quiz Page**

**src/pages/QuizPage.jsx:**
- Category selection screen
- Quiz session (10 questions)
- Timer per question (15 seconds)
- Immediate feedback (correct/wrong)
- Score tracking
- 2 CNE per correct answer
- Final results screen

### **Step 5.4: Implement Quiz Logic**

```javascript
const [currentQuestion, setCurrentQuestion] = useState(0);
const [score, setScore] = useState(0);
const [timeLeft, setTimeLeft] = useState(15);
const [answered, setAnswered] = useState(false);

const handleAnswer = (selectedIndex) => {
  if (answered) return;
  
  setAnswered(true);
  const correct = selectedIndex === questions[currentQuestion].correctAnswer;
  
  if (correct) {
    setScore(score + 1);
    rewardsService.claimQuizReward();
  }

  setTimeout(() => {
    if (currentQuestion < 9) {
      setCurrentQuestion(currentQuestion + 1);
      setAnswered(false);
      setTimeLeft(15);
    } else {
      // Show final score
      showResults();
    }
  }, 2000);
};
```

✅ **Deliverables:**
- Quiz categories page
- Functional quiz with 10 questions
- Timer working (15 seconds)
- Answer validation
- 2 CNE reward per correct answer
- Final score display
- Progress saved to Firestore

---

## 📋 PHASE 6: Spin2Earn Wheel (Week 3)

### **Step 6.1: Install Dependencies**

```bash
npm install framer-motion
```

### **Step 6.2: Create Spin Wheel Component**

**src/components/spin/SpinWheel.jsx:**
```javascript
import { motion } from 'framer-motion';
import { useState } from 'react';

const SpinWheel = ({ prizes, onSpinComplete }) => {
  const [rotation, setRotation] = useState(0);
  const [isSpinning, setIsSpinning] = useState(false);

  const spinWheel = () => {
    if (isSpinning) return;

    setIsSpinning(true);
    
    // Calculate winner based on weighted probabilities
    const winner = selectWinner(prizes);
    const winnerIndex = prizes.indexOf(winner);
    
    // Calculate final rotation
    const segmentAngle = 360 / prizes.length;
    const targetRotation = 360 * 5 + (winnerIndex * segmentAngle);
    
    setRotation(targetRotation);

    setTimeout(() => {
      setIsSpinning(false);
      onSpinComplete(winner);
    }, 3000);
  };

  const selectWinner = (prizes) => {
    const totalWeight = prizes.reduce((sum, p) => sum + p.weight, 0);
    let random = Math.random() * totalWeight;
    
    for (const prize of prizes) {
      random -= prize.weight;
      if (random <= 0) return prize;
    }
    return prizes[0];
  };

  return (
    <div className="relative">
      <motion.div
        animate={{ rotate: rotation }}
        transition={{ duration: 3, ease: 'easeOut' }}
        className="wheel"
      >
        {prizes.map((prize, index) => (
          <div key={index} className="wheel-segment" style={{
            transform: `rotate(${(360 / prizes.length) * index}deg)`
          }}>
            <span>{prize.label}</span>
          </div>
        ))}
      </motion.div>
      
      <button onClick={spinWheel} disabled={isSpinning}>
        SPIN
      </button>
    </div>
  );
};
```

### **Step 6.3: Create Spin Page**

**src/pages/SpinPage.jsx:**
- Spin wheel display
- Daily spins counter (5 max)
- Prize breakdown display
- Spin history
- Reward claiming after spin

### **Step 6.4: Implement Spin Limits**

```javascript
const [spinsUsed, setSpinsUsed] = useState(0);
const MAX_SPINS = 5;

useEffect(() => {
  const lastSpinDate = localStorage.getItem('lastSpinDate');
  const today = new Date().toDateString();
  
  if (lastSpinDate !== today) {
    localStorage.setItem('spinsUsed', '0');
    localStorage.setItem('lastSpinDate', today);
    setSpinsUsed(0);
  } else {
    const used = parseInt(localStorage.getItem('spinsUsed') || '0');
    setSpinsUsed(used);
  }
}, []);

const handleSpin = () => {
  if (spinsUsed >= MAX_SPINS) {
    toast.error('Daily spin limit reached!');
    return;
  }

  // Spin logic...
  setSpinsUsed(spinsUsed + 1);
  localStorage.setItem('spinsUsed', String(spinsUsed + 1));
};
```

✅ **Deliverables:**
- Animated spin wheel
- Weighted probability system working
- Daily limit enforcement (5 spins)
- Prize claiming (0.5 - 1000 CNE)
- Smooth animations
- Spin history display

---

## 📋 PHASE 7: Chat System (Week 4)

### **Step 7.1: Install Dependencies**

```bash
npm install emoji-picker-react date-fns
```

### **Step 7.2: Create Chat Service**

**src/services/chat.service.js:**
```javascript
import { 
  collection, 
  addDoc, 
  query, 
  orderBy, 
  limit, 
  onSnapshot,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from './firebase';

export const chatService = {
  subscribeToMessages(callback, messageLimit = 100) {
    const q = query(
      collection(db, 'chat_messages'),
      orderBy('timestamp', 'desc'),
      limit(messageLimit)
    );

    return onSnapshot(q, (snapshot) => {
      const messages = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() }))
        .reverse();
      callback(messages);
    });
  },

  async sendMessage(userId, username, message, avatarUrl) {
    await addDoc(collection(db, 'chat_messages'), {
      userId,
      username,
      message,
      avatarUrl,
      timestamp: serverTimestamp(),
      isSystem: false
    });

    // Small reward for chatting
    await rewardsService.claimChatReward();
  }
};
```

### **Step 7.3: Create Chat Components**

**Components:**
1. **ChatMessage.jsx** - Individual message bubble
2. **ChatInput.jsx** - Input field with emoji picker
3. **OnlineUsers.jsx** - Online user count display
4. **EmojiPicker.jsx** - Emoji selector

### **Step 7.4: Create Chat Page**

**src/pages/ChatPage.jsx:**
- Real-time message list
- Auto-scroll to bottom
- User avatars
- Timestamp display (date-fns)
- Emoji picker
- 0.1 CNE reward per message
- System messages support

### **Step 7.5: Implement Real-time Updates**

```javascript
const [messages, setMessages] = useState([]);
const messagesEndRef = useRef(null);

useEffect(() => {
  const unsubscribe = chatService.subscribeToMessages(setMessages);
  return unsubscribe;
}, []);

useEffect(() => {
  messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
}, [messages]);
```

✅ **Deliverables:**
- Real-time chat working
- Messages sync across all users
- Emoji picker functional
- Auto-scroll to latest message
- 0.1 CNE per message sent
- User avatars displaying

---

## 📋 PHASE 8: Daily Check-in & Wallet (Week 4)

### **Step 8.1: Create Daily Check-in Page**

**src/pages/DailyCheckinPage.jsx:**
- Visual check-in calendar (30 days)
- Current streak display
- Check-in button
- 28 CNE reward
- Streak bonuses (7-day: 196 CNE, 30-day: 840 CNE)
- Next check-in countdown

### **Step 8.2: Implement Check-in Logic**

```javascript
const [canCheckIn, setCanCheckIn] = useState(false);
const [streak, setStreak] = useState(0);

useEffect(() => {
  const lastCheckIn = localStorage.getItem('lastCheckInDate');
  const today = new Date().toDateString();
  
  if (lastCheckIn !== today) {
    setCanCheckIn(true);
  }
  
  const currentStreak = parseInt(localStorage.getItem('checkinStreak') || '0');
  setStreak(currentStreak);
}, []);

const handleCheckIn = async () => {
  await rewardsService.claimCheckInReward();
  
  const newStreak = streak + 1;
  setStreak(newStreak);
  
  localStorage.setItem('lastCheckInDate', new Date().toDateString());
  localStorage.setItem('checkinStreak', String(newStreak));
  
  // Check for streak bonuses
  if (newStreak === 7) {
    await rewardsService.claimStreakBonus(196);
  } else if (newStreak === 30) {
    await rewardsService.claimStreakBonus(840);
  }
  
  setCanCheckIn(false);
  toast.success('🎉 Daily check-in complete! +28 CNE');
};
```

### **Step 8.3: Create Wallet Page**

**src/pages/WalletPage.jsx:**
- Total balance card
- Locked vs Unlocked balance
- Transaction history list
- Earnings breakdown (pie chart with recharts)
- Hedera wallet info
- Copy account ID button

### **Step 8.4: Create Transaction History Component**

**src/components/wallet/TransactionHistory.jsx:**
```javascript
const TransactionHistory = ({ userId }) => {
  const [transactions, setTransactions] = useState([]);

  useEffect(() => {
    const q = query(
      collection(db, 'rewards_log'),
      where('userId', '==', userId),
      orderBy('timestamp', 'desc'),
      limit(50)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const txs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setTransactions(txs);
    });

    return unsubscribe;
  }, [userId]);

  return (
    <div className="space-y-2">
      {transactions.map(tx => (
        <div key={tx.id} className="flex justify-between p-3 bg-dark-card rounded">
          <span>{tx.type}</span>
          <span className="text-primary">+{tx.amount} CNE</span>
          <span className="text-sm text-dark-text">
            {formatDistance(tx.timestamp?.toDate(), new Date(), { addSuffix: true })}
          </span>
        </div>
      ))}
    </div>
  );
};
```

✅ **Deliverables:**
- Daily check-in functional (28 CNE)
- Streak tracking working
- Bonus rewards at 7 and 30 days
- Wallet page showing all balances
- Transaction history real-time
- Earnings breakdown chart

---

## 📋 PHASE 9: Market Data & News (Week 5)

### **Step 9.1: Create Market Service**

**src/services/market.service.js:**
```javascript
import axios from 'axios';

export const marketService = {
  async getCryptocurrencies(limit = 100) {
    const response = await axios.get(
      `https://api.coingecko.com/api/v3/coins/markets`,
      {
        params: {
          vs_currency: 'usd',
          order: 'market_cap_desc',
          per_page: limit,
          page: 1,
          sparkline: false
        }
      }
    );
    return response.data;
  },

  async getCryptoDetails(coinId) {
    const response = await axios.get(
      `https://api.coingecko.com/api/v3/coins/${coinId}`
    );
    return response.data;
  }
};
```

### **Step 9.2: Create Market Page**

**src/pages/MarketPage.jsx:**
- Top 100 cryptocurrencies
- Price, 24h change, market cap
- Search functionality
- Sorting options
- Color-coded price changes (green/red)
- Click for details

### **Step 9.3: Create Crypto Card Component**

**src/components/market/CryptoCard.jsx:**
```javascript
const CryptoCard = ({ crypto }) => {
  const priceChange = crypto.price_change_percentage_24h;
  const isPositive = priceChange >= 0;

  return (
    <div className="bg-dark-card p-4 rounded-lg hover:bg-dark-border transition">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <img src={crypto.image} alt={crypto.name} className="w-10 h-10" />
          <div>
            <h3 className="font-bold">{crypto.symbol.toUpperCase()}</h3>
            <p className="text-sm text-dark-text">{crypto.name}</p>
          </div>
        </div>
        
        <div className="text-right">
          <p className="font-bold">${crypto.current_price.toLocaleString()}</p>
          <p className={isPositive ? 'text-accent-green' : 'text-accent-red'}>
            {isPositive ? '+' : ''}{priceChange.toFixed(2)}%
          </p>
        </div>
      </div>
    </div>
  );
};
```

### **Step 9.4: Create News Page**

**src/pages/NewsPage.jsx:**
- Crypto news feed (can use RSS feeds or crypto news APIs)
- Article cards with images
- External links
- Share buttons
- Bookmark functionality

✅ **Deliverables:**
- Market page showing top 100 cryptos
- Real-time price data from CoinGecko
- Search and sorting working
- News feed displaying articles
- Responsive card layouts

---

## 📋 PHASE 10: AI Assistant (ExtraAI) (Week 5)

### **Step 10.1: Create OpenAI Service**

**src/services/openai.service.js:**
```javascript
import axios from 'axios';

export const openAIService = {
  async sendMessage(message, conversationHistory = []) {
    try {
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'system',
              content: 'You are a crypto education assistant. Provide accurate, concise information about cryptocurrencies, blockchain, and DeFi.'
            },
            ...conversationHistory,
            {
              role: 'user',
              content: message
            }
          ],
          max_tokens: 500
        },
        {
          headers: {
            'Authorization': `Bearer ${import.meta.env.VITE_OPENAI_API_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data.choices[0].message.content;
    } catch (error) {
      throw new Error('Failed to get AI response');
    }
  }
};
```

### **Step 10.2: Create AI Page**

**src/pages/AIPage.jsx:**
- Chat interface similar to ChatGPT
- Message history
- Typing indicator
- Daily limit (10 questions)
- 0.5 CNE per interaction
- Save conversation to localStorage
- Clear history button

### **Step 10.3: Implement AI Chat Logic**

```javascript
const [messages, setMessages] = useState([]);
const [loading, setLoading] = useState(false);
const [questionsAsked, setQuestionsAsked] = useState(0);
const DAILY_LIMIT = 10;

const handleSendMessage = async (userMessage) => {
  if (questionsAsked >= DAILY_LIMIT) {
    toast.error('Daily question limit reached!');
    return;
  }

  // Add user message
  const userMsg = { role: 'user', content: userMessage, timestamp: new Date() };
  setMessages(prev => [...prev, userMsg]);
  setLoading(true);

  try {
    const response = await openAIService.sendMessage(userMessage, messages);
    
    // Add AI response
    const aiMsg = { role: 'assistant', content: response, timestamp: new Date() };
    setMessages(prev => [...prev, aiMsg]);
    
    // Claim reward
    await rewardsService.claimAIReward();
    setQuestionsAsked(prev => prev + 1);
    
  } catch (error) {
    toast.error('Failed to get response');
  } finally {
    setLoading(false);
  }
};
```

✅ **Deliverables:**
- AI chat interface functional
- OpenAI integration working
- Conversation history persisted
- Daily limit enforced
- 0.5 CNE per interaction
- Typing indicator

---

## 📋 PHASE 11: Profile & Settings (Week 6)

### **Step 11.1: Create Profile Page**

**src/pages/ProfilePage.jsx:**
- User info display (name, email, join date)
- Profile picture (if available)
- Edit profile button
- CNE balance summary
- Total earnings stats
- Referral code with share button
- Logout button
- Admin dashboard link (if admin)

### **Step 11.2: Create Settings Page**

**src/pages/SettingsPage.jsx:**
- Account settings
- Notification preferences
- Theme toggle (dark/light - if implementing)
- Language selection (future)
- Privacy settings
- Delete account option

### **Step 11.3: Implement Profile Editing**

```javascript
const [editing, setEditing] = useState(false);
const [displayName, setDisplayName] = useState(user.displayName);

const handleSaveProfile = async () => {
  await updateProfile(auth.currentUser, { displayName });
  await updateDoc(doc(db, 'users', user.uid), { displayName });
  toast.success('Profile updated!');
  setEditing(false);
};
```

✅ **Deliverables:**
- Profile page showing user info
- Edit profile functionality
- Settings page with preferences
- Referral code sharing
- Logout working

---

## 📋 PHASE 12: Admin Dashboard (Week 6)

### **Step 12.1: Create Admin Service**

**src/services/admin.service.js:**
```javascript
import { collection, getDocs, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from './firebase';

const SUPER_ADMIN_EMAILS = [
  'yerinssaibs@gmail.com',
  'elitepr@coinnewsextra.com'
];

export const adminService = {
  isSuperAdmin(email) {
    return SUPER_ADMIN_EMAILS.includes(email);
  },

  async getAllUsers() {
    const snapshot = await getDocs(collection(db, 'users'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  },

  async updateUser(userId, data) {
    await updateDoc(doc(db, 'users', userId), data);
  },

  async deleteUser(userId) {
    await deleteDoc(doc(db, 'users', userId));
  }
};
```

### **Step 12.2: Create Admin Dashboard**

**src/pages/AdminPage.jsx:**
- Overview stats (total users, total rewards, etc.)
- User management table
- Content management
- Recent activity log
- System settings

### **Step 12.3: Create Admin Components**

1. **UserManagementTable.jsx** - List all users, edit, delete
2. **ContentManager.jsx** - Add/edit videos, quizzes
3. **StatsCards.jsx** - Dashboard metrics

✅ **Deliverables:**
- Admin dashboard accessible by super admins only
- User management functional
- Can view all users and their balances
- Basic content management

---

## 📋 PHASE 13: Live TV & Advanced Features (Week 7)

### **Step 13.1: Create Live TV Page**

**src/pages/LiveTVPage.jsx:**
- YouTube live stream embed
- Live chat integration (reuse chat components)
- Viewer count
- Watch time tracking
- 7 CNE reward after qualifying watch time

### **Step 13.2: Create Other Pages**

1. **ExplorePage.jsx** - Content discovery
2. **SummitPage.jsx** - Events calendar
3. **ProgramPage.jsx** - TV schedule

### **Step 13.3: Implement Live Streaming (Optional - Advanced)**

**If implementing Agora Web SDK:**

```bash
npm install agora-rtc-sdk-ng
```

**src/services/agora.service.js:**
```javascript
import AgoraRTC from 'agora-rtc-sdk-ng';
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase';

export const agoraService = {
  client: null,

  async initializeClient() {
    this.client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
  },

  async joinChannel(channelName) {
    // Get token from Firebase Function
    const getAgoraToken = httpsCallable(functions, 'generateAgoraToken');
    const result = await getAgoraToken({ channel: channelName, uid: 0 });
    
    const { token, appId } = result.data;

    await this.client.join(appId, channelName, token, 0);
  },

  async publishLocalStream() {
    const localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
    const localVideoTrack = await AgoraRTC.createCameraVideoTrack();
    await this.client.publish([localAudioTrack, localVideoTrack]);
  }
};
```

✅ **Deliverables:**
- Live TV page with YouTube stream
- Explore, Summit, Program pages created
- All pages accessible from navigation
- Live streaming (if implementing Agora)

---

## 📋 PHASE 14: Play Extra (Battle Game) (Week 7)

### **Step 14.1: Create Play Extra Service**

**src/services/playextra.service.js:**
```javascript
import { 
  collection, 
  doc, 
  setDoc, 
  updateDoc, 
  onSnapshot,
  arrayUnion,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from './firebase';

export const playExtraService = {
  async createBattle(roomId, stakeAmount, userId) {
    const battleId = `${roomId}_${Date.now()}`;
    await setDoc(doc(db, 'battles', battleId), {
      roomId,
      stakeAmount,
      players: [{ userId, stake: stakeAmount }],
      status: 'waiting',
      createdAt: serverTimestamp()
    });
    return battleId;
  },

  async joinBattle(battleId, userId, stakeAmount) {
    await updateDoc(doc(db, 'battles', battleId), {
      players: arrayUnion({ userId, stake: stakeAmount })
    });
  },

  subscribeToBattle(battleId, callback) {
    return onSnapshot(doc(db, 'battles', battleId), (snapshot) => {
      callback({ id: snapshot.id, ...snapshot.data() });
    });
  }
};
```

### **Step 14.2: Create Play Extra Page**

**src/pages/PlayExtraPage.jsx:**
- Room selection (Rookie, Pro, Elite)
- Battle lobby (waiting for players)
- Live battle view (wheel spin)
- Winner announcement
- Earnings/losses display

### **Step 14.3: Implement Battle Logic**

- Real-time player updates via Firestore
- Wheel spin when all players ready
- Winner selection algorithm
- CNE distribution

✅ **Deliverables:**
- Play Extra battle rooms created
- Join/create battles working
- Real-time player sync
- Winner selection functional
- CNE stakes and payouts working

---

## 📋 PHASE 15: Polish & Optimization (Week 8)

### **Step 15.1: Responsive Design Audit**

- Test all pages on mobile, tablet, desktop
- Fix layout issues
- Optimize images
- Ensure touch-friendly elements

### **Step 15.2: Performance Optimization**

```javascript
// Lazy load routes
const VideosPage = lazy(() => import('./pages/VideosPage'));
const QuizPage = lazy(() => import('./pages/QuizPage'));

// Use Suspense
<Suspense fallback={<Loader />}>
  <Routes>
    <Route path="/videos" element={<VideosPage />} />
  </Routes>
</Suspense>
```

### **Step 15.3: Add Loading States**

- Skeleton loaders for data fetching
- Loading spinners for actions
- Progress indicators

### **Step 15.4: Error Handling**

- Error boundaries for React errors
- Retry mechanisms for failed requests
- User-friendly error messages

### **Step 15.5: Accessibility**

- Keyboard navigation
- ARIA labels
- Focus indicators
- Screen reader support

### **Step 15.6: SEO Optimization**

- Meta tags in index.html
- Open Graph tags
- Structured data

✅ **Deliverables:**
- All pages responsive
- Performance optimized
- Loading states everywhere
- Error handling robust
- Accessibility improved

---

## 📋 PHASE 16: Testing & Deployment (Week 8)

### **Step 16.1: Testing**

**Manual Testing:**
- Test all user flows
- Test on different browsers
- Test on different devices
- Test edge cases

**Key Test Scenarios:**
- ✅ Signup with email
- ✅ Signup with Google
- ✅ Login/logout
- ✅ Video watching and reward
- ✅ Quiz completion
- ✅ Spin wheel
- ✅ Chat messaging
- ✅ Daily check-in
- ✅ Balance updates
- ✅ Admin access

### **Step 16.2: Build for Production**

```bash
npm run build
```

### **Step 16.3: Configure Firebase Hosting**

**firebase.json (update existing):**
```json
{
  "hosting": [
    {
      "target": "web-app",
      "public": "web/dist",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ],
      "headers": [
        {
          "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "max-age=31536000"
            }
          ]
        },
        {
          "source": "**/*.@(js|css)",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "max-age=31536000"
            }
          ]
        }
      ]
    }
  ]
}
```

### **Step 16.4: Deploy to Firebase**

```bash
# Login to Firebase
firebase login

# Deploy to Firebase Hosting
firebase deploy --only hosting:web-app

# Or deploy everything
firebase deploy
```

### **Step 16.5: Verify Deployment**

- Test production URL
- Check all features working
- Monitor Firebase console for errors
- Check Analytics

✅ **Deliverables:**
- Production build created
- Deployed to Firebase Hosting
- All features verified in production
- URL accessible: https://coinnewsextratv.web.app

---

## 📊 Final Checklist

### **Core Features**
- [x] Authentication (Email + Google)
- [x] Home Dashboard
- [x] Balance Display & Sync
- [x] Video Library & Watch2Earn
- [x] Quiz System
- [x] Spin2Earn Wheel
- [x] Chat System
- [x] Daily Check-in
- [x] Wallet Page
- [x] Market Data
- [x] News Feed
- [x] AI Assistant (ExtraAI)
- [x] Profile & Settings
- [x] Live TV
- [x] Play Extra (Battles)
- [x] Admin Dashboard
- [x] Explore, Summit, Program pages

### **Technical Requirements**
- [x] Firebase Auth integrated
- [x] Firestore real-time sync
- [x] Cloud Functions connected
- [x] Responsive design (mobile/tablet/desktop)
- [x] Dark theme
- [x] Toast notifications
- [x] Error handling
- [x] Loading states
- [x] Offline persistence
- [x] Analytics tracking

### **Deployment**
- [x] Production build optimized
- [x] Firebase Hosting configured
- [x] Environment variables secured
- [x] Domain configured (optional)
- [x] SSL certificate active

---

## 🚀 Post-Launch Tasks

### **Monitoring**
- Monitor Firebase Analytics
- Track user engagement
- Monitor error rates
- Check performance metrics

### **Future Enhancements**
1. **PWA Features**
   - Service worker for offline mode
   - Install prompt
   - Push notifications (Web Push API)

2. **Advanced Features**
   - Live streaming with Agora
   - NFT marketplace integration
   - Hedera wallet connection (non-custodial)
   - Token withdrawal to external wallets

3. **Optimizations**
   - Server-side rendering (Next.js migration)
   - Edge caching
   - Image optimization
   - Code splitting improvements

4. **Social Features**
   - User profiles (public)
   - Leaderboards
   - Social feed
   - Friend system

---

## 📝 Development Tips

### **Best Practices**
1. **Commit frequently** - Small, logical commits
2. **Test on mobile first** - Mobile-first development
3. **Use Firebase emulator** for local development
4. **Keep components small** - Single responsibility
5. **Reuse components** - DRY principle
6. **Handle errors gracefully** - User-friendly messages
7. **Optimize images** - WebP format, lazy loading
8. **Use TypeScript** (optional but recommended)

### **Common Pitfalls to Avoid**
- ❌ Don't expose API keys in client code
- ❌ Don't forget to unsubscribe from Firestore listeners
- ❌ Don't skip loading states
- ❌ Don't ignore mobile responsiveness
- ❌ Don't duplicate reward logic (use Cloud Functions)
- ❌ Don't forget rate limiting on earning activities

### **Debugging Tips**
- Use React DevTools
- Use Firebase Console for Firestore queries
- Use Network tab to check API calls
- Console.log strategically
- Use breakpoints in browser DevTools

---

## 🎯 Success Metrics

### **Launch Goals**
- ✅ All core features functional
- ✅ Zero critical bugs
- ✅ Mobile responsive
- ✅ Page load < 3 seconds
- ✅ 99.9% uptime

### **User Experience Goals**
- Intuitive navigation
- Fast reward claiming
- Smooth animations
- Clear feedback on actions
- Consistent with mobile app experience

---

## 📞 Support & Resources

### **Documentation**
- [React Documentation](https://react.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Vite Guide](https://vitejs.dev/guide/)

### **Community**
- React Discord
- Firebase Discord
- Stack Overflow

---

**END OF IMPLEMENTATION PLAN**

🎉 **You're now ready to build the CoinNewsExtra TV Web Application!**

Follow this plan step-by-step, and you'll have a fully functional web version that mirrors your Flutter mobile app. Good luck! 🚀
