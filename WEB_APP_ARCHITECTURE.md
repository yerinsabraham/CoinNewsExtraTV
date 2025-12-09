# CoinNewsExtra TV - Web App Architecture

**Date**: December 9, 2025  
**Target Platform**: Web Browsers (Chrome, Firefox, Safari, Edge)  
**Framework**: React 18+  
**Build Tool**: Vite  

---

## 🎯 Technology Stack Decisions

### **Frontend Framework: React 18+**

**Why React?**
- ✅ Component-based architecture matches Flutter's widget system
- ✅ Large ecosystem with mature libraries
- ✅ Excellent performance with Virtual DOM
- ✅ Strong TypeScript support
- ✅ Hooks for state management (similar to Provider pattern)
- ✅ Easy Firebase integration
- ✅ Great developer experience
- ✅ SEO-friendly with SSR options (if needed later)

**Alternative Considered:**
- Next.js - Too heavy for our use case, adds SSR complexity
- Vue.js - Smaller ecosystem for Firebase/Web3
- Angular - Steeper learning curve, more opinionated

---

## 🏗️ Project Structure

```
web/
├── public/
│   ├── index.html
│   ├── manifest.json (PWA)
│   ├── robots.txt
│   └── assets/
│       ├── icons/
│       ├── images/
│       ├── avatars/
│       └── fonts/
├── src/
│   ├── App.jsx
│   ├── main.jsx
│   ├── index.css
│   │
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.jsx
│   │   │   ├── Card.jsx
│   │   │   ├── Modal.jsx
│   │   │   ├── Loader.jsx
│   │   │   └── Notification.jsx
│   │   ├── layout/
│   │   │   ├── Header.jsx
│   │   │   ├── Sidebar.jsx
│   │   │   ├── Footer.jsx
│   │   │   └── BottomNav.jsx (mobile)
│   │   ├── auth/
│   │   │   ├── LoginForm.jsx
│   │   │   ├── SignupForm.jsx
│   │   │   ├── GoogleSignInButton.jsx
│   │   │   └── PrivateRoute.jsx
│   │   ├── home/
│   │   │   ├── BannerCarousel.jsx
│   │   │   ├── QuickFeatures.jsx
│   │   │   └── RecentActivity.jsx
│   │   ├── videos/
│   │   │   ├── VideoCard.jsx
│   │   │   ├── VideoPlayer.jsx
│   │   │   ├── VideoGrid.jsx
│   │   │   └── CategoryFilter.jsx
│   │   ├── quiz/
│   │   │   ├── QuizCard.jsx
│   │   │   ├── QuestionDisplay.jsx
│   │   │   ├── Timer.jsx
│   │   │   └── ScoreDisplay.jsx
│   │   ├── spin/
│   │   │   ├── SpinWheel.jsx
│   │   │   ├── PrizeDisplay.jsx
│   │   │   └── SpinHistory.jsx
│   │   ├── chat/
│   │   │   ├── ChatMessage.jsx
│   │   │   ├── ChatInput.jsx
│   │   │   ├── EmojiPicker.jsx
│   │   │   └── OnlineUsers.jsx
│   │   ├── wallet/
│   │   │   ├── BalanceCard.jsx
│   │   │   ├── TransactionHistory.jsx
│   │   │   └── EarningsBreakdown.jsx
│   │   ├── market/
│   │   │   ├── CryptoCard.jsx
│   │   │   ├── PriceChart.jsx
│   │   │   └── MarketSearch.jsx
│   │   ├── profile/
│   │   │   ├── ProfileHeader.jsx
│   │   │   ├── StatsDisplay.jsx
│   │   │   └── ReferralCard.jsx
│   │   └── admin/
│   │       ├── AdminDashboard.jsx
│   │       ├── UserManagement.jsx
│   │       └── ContentManager.jsx
│   │
│   ├── pages/
│   │   ├── HomePage.jsx
│   │   ├── LoginPage.jsx
│   │   ├── SignupPage.jsx
│   │   ├── VideosPage.jsx
│   │   ├── LiveTVPage.jsx
│   │   ├── QuizPage.jsx
│   │   ├── SpinPage.jsx
│   │   ├── ChatPage.jsx
│   │   ├── AIPage.jsx
│   │   ├── WalletPage.jsx
│   │   ├── ProfilePage.jsx
│   │   ├── MarketPage.jsx
│   │   ├── NewsPage.jsx
│   │   ├── ExplorePage.jsx
│   │   ├── SummitPage.jsx
│   │   ├── ProgramPage.jsx
│   │   ├── PlayExtraPage.jsx
│   │   ├── DailyCheckinPage.jsx
│   │   ├── SettingsPage.jsx
│   │   ├── NotificationsPage.jsx
│   │   └── AdminPage.jsx
│   │
│   ├── hooks/
│   │   ├── useAuth.js
│   │   ├── useBalance.js
│   │   ├── useFirestore.js
│   │   ├── useRealtimeUpdates.js
│   │   ├── useLocalStorage.js
│   │   └── useRewards.js
│   │
│   ├── contexts/
│   │   ├── AuthContext.jsx
│   │   ├── BalanceContext.jsx
│   │   ├── ThemeContext.jsx
│   │   └── NotificationContext.jsx
│   │
│   ├── services/
│   │   ├── firebase.js (config)
│   │   ├── auth.service.js
│   │   ├── firestore.service.js
│   │   ├── functions.service.js
│   │   ├── storage.service.js
│   │   ├── rewards.service.js
│   │   ├── openai.service.js
│   │   ├── coingecko.service.js
│   │   └── agora.service.js
│   │
│   ├── utils/
│   │   ├── constants.js
│   │   ├── helpers.js
│   │   ├── formatters.js
│   │   ├── validators.js
│   │   └── api.js
│   │
│   ├── styles/
│   │   ├── globals.css
│   │   ├── theme.js
│   │   ├── colors.js
│   │   └── typography.js
│   │
│   └── assets/
│       └── (imported from Flutter app)
│
├── .env
├── .env.production
├── .gitignore
├── package.json
├── vite.config.js
├── tailwind.config.js
├── postcss.config.js
└── README.md
```

---

## 📦 Core Dependencies

### **Essential Libraries**

```json
{
  "dependencies": {
    // Core
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    
    // Firebase
    "firebase": "^10.7.1",
    
    // UI & Styling
    "tailwindcss": "^3.4.0",
    "@headlessui/react": "^1.7.17",
    "framer-motion": "^10.16.16",
    
    // Video Players
    "react-youtube": "^10.1.0",
    "react-player": "^2.13.0",
    
    // Real-time & WebRTC
    "agora-rtc-sdk-ng": "^4.20.0",
    "socket.io-client": "^4.6.0",
    
    // State Management
    "zustand": "^4.4.7",
    
    // Forms & Validation
    "react-hook-form": "^7.49.2",
    "zod": "^3.22.4",
    
    // Data Fetching
    "axios": "^1.6.2",
    "swr": "^2.2.4",
    
    // UI Components
    "react-icons": "^4.12.0",
    "react-hot-toast": "^2.4.1",
    "emoji-picker-react": "^4.5.16",
    "react-confetti": "^6.1.0",
    
    // Charts
    "recharts": "^2.10.3",
    
    // Utilities
    "date-fns": "^3.0.6",
    "clsx": "^2.0.0",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32"
  }
}
```

---

## 🎨 Styling Approach

### **Tailwind CSS + Custom CSS**

**Why Tailwind?**
- ✅ Utility-first approach (fast development)
- ✅ Responsive design built-in
- ✅ Dark mode support
- ✅ Small bundle size (purged unused classes)
- ✅ Consistent design system
- ✅ Easy to maintain

**Custom CSS for:**
- Complex animations
- Wheel spinning physics
- Video player overlays
- Custom scrollbars

**Theme Configuration:**
```javascript
// tailwind.config.js
module.exports = {
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
          border: '#2A2A2A'
        }
      },
      fontFamily: {
        lato: ['Lato', 'sans-serif']
      }
    }
  }
}
```

---

## 🔥 Firebase Configuration

### **Services Used**

1. **Firebase Authentication**
   - Email/Password auth
   - Google OAuth provider
   - Session management
   - Token refresh

2. **Cloud Firestore**
   - Real-time database
   - Offline persistence
   - Security rules enforcement
   - Batch operations

3. **Cloud Functions**
   - Reward processing
   - User onboarding
   - Agora token generation
   - Admin operations

4. **Firebase Hosting**
   - Static site hosting
   - CDN distribution
   - SSL certificates
   - Custom domain support

5. **Firebase Storage** (if needed)
   - User avatars
   - Admin uploads

6. **Firebase Analytics**
   - User behavior tracking
   - Event logging

### **Firebase Initialization**

```javascript
// src/services/firebase.js
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
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
```

---

## 🔄 State Management Strategy

### **Zustand for Global State**

**Why Zustand over Redux?**
- ✅ Simpler API (less boilerplate)
- ✅ No providers needed
- ✅ Built-in DevTools support
- ✅ TypeScript-friendly
- ✅ Small bundle size (1KB)
- ✅ Can use outside React

**Store Structure:**

```javascript
// stores/authStore.js
import create from 'zustand';

export const useAuthStore = create((set) => ({
  user: null,
  loading: true,
  setUser: (user) => set({ user, loading: false }),
  logout: () => set({ user: null })
}));

// stores/balanceStore.js
export const useBalanceStore = create((set) => ({
  balance: 0,
  totalEarnings: 0,
  lockedBalance: 0,
  updateBalance: (balance) => set({ balance }),
  addReward: (amount) => set((state) => ({
    balance: state.balance + amount,
    totalEarnings: state.totalEarnings + amount
  }))
}));
```

### **React Context for Theme & Notifications**

---

## 🎬 Video Integration

### **YouTube Player (react-youtube)**

```javascript
import YouTube from 'react-youtube';

const VideoPlayer = ({ videoId, onEnd }) => {
  const opts = {
    height: '100%',
    width: '100%',
    playerVars: {
      autoplay: 0,
      controls: 1,
      rel: 0,
      modestbranding: 1
    }
  };

  return (
    <YouTube
      videoId={videoId}
      opts={opts}
      onEnd={onEnd}
    />
  );
};
```

---

## 🎮 Real-time Features

### **1. Chat System (Firestore Real-time)**

```javascript
import { collection, query, orderBy, limit, onSnapshot } from 'firebase/firestore';

const useChatMessages = () => {
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    const q = query(
      collection(db, 'chat_messages'),
      orderBy('timestamp', 'desc'),
      limit(100)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setMessages(msgs.reverse());
    });

    return unsubscribe;
  }, []);

  return messages;
};
```

### **2. Live Streaming (Agora Web SDK)**

```javascript
import AgoraRTC from 'agora-rtc-sdk-ng';

const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

const joinChannel = async (channel, token, uid) => {
  await client.join(APP_ID, channel, token, uid);
  
  const localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
  const localVideoTrack = await AgoraRTC.createCameraVideoTrack();
  
  await client.publish([localAudioTrack, localVideoTrack]);
};
```

### **3. Play Extra Battles (WebSocket alternative)**

- Use Firestore real-time listeners for battle state
- Cloud Functions for battle logic
- Optimistic UI updates

---

## 📱 Responsive Design Strategy

### **Breakpoints**

```javascript
// Mobile First Approach
sm: '640px',   // Mobile landscape
md: '768px',   // Tablet
lg: '1024px',  // Desktop
xl: '1280px',  // Large desktop
2xl: '1536px'  // Extra large
```

### **Layout Patterns**

- **Mobile (<768px)**: Single column, bottom navigation
- **Tablet (768px-1024px)**: Two columns where appropriate
- **Desktop (>1024px)**: Sidebar navigation, multi-column layouts

### **Touch-Friendly Design**
- Minimum touch target: 44x44px
- Swipe gestures for carousels
- Large buttons for primary actions

---

## 🔒 Security Implementation

### **1. Environment Variables**
```env
VITE_FIREBASE_API_KEY=xxx
VITE_FIREBASE_AUTH_DOMAIN=xxx
VITE_FIREBASE_PROJECT_ID=xxx
VITE_OPENAI_API_KEY=xxx
VITE_AGORA_APP_ID=xxx
```

### **2. Firebase Security Rules**
- Already configured in existing Firebase project
- Use same rules as mobile app
- Add web-specific rate limiting if needed

### **3. API Key Protection**
- Never expose private keys in client
- Use Firebase Functions for sensitive operations
- Implement CORS properly

### **4. Input Validation**
- Use Zod for schema validation
- Sanitize user inputs
- XSS protection

---

## 🚀 Performance Optimizations

### **1. Code Splitting**
```javascript
// Route-based code splitting
const VideosPage = lazy(() => import('./pages/VideosPage'));
const QuizPage = lazy(() => import('./pages/QuizPage'));
```

### **2. Image Optimization**
- Lazy loading images
- WebP format with fallbacks
- Responsive images with srcset

### **3. Bundle Size**
- Tree shaking unused code
- Dynamic imports
- Analyze bundle with rollup-plugin-visualizer

### **4. Caching Strategy**
- Service Worker for offline support (PWA)
- Cache API responses with SWR
- LocalStorage for user preferences

---

## 🧪 Testing Strategy (Optional but Recommended)

### **Testing Libraries**
- **Vitest**: Unit tests
- **React Testing Library**: Component tests
- **Playwright/Cypress**: E2E tests

### **Test Coverage Focus**
- Authentication flows
- Reward calculations
- Payment/withdrawal logic
- Critical user paths

---

## 📊 Analytics & Monitoring

### **Firebase Analytics Events**
```javascript
import { logEvent } from 'firebase/analytics';

// Track user actions
logEvent(analytics, 'video_watched', {
  video_id: videoId,
  reward_earned: 7
});

logEvent(analytics, 'quiz_completed', {
  category: 'Bitcoin',
  score: 8,
  tokens_earned: 16
});
```

### **Error Tracking**
- Console errors logged to Firebase
- User feedback form for bug reports
- Admin notification for critical errors

---

## 🌐 PWA Features (Progressive Web App)

### **Manifest.json**
```json
{
  "name": "CoinNewsExtra TV",
  "short_name": "CNE TV",
  "description": "Watch to Earn Crypto Education Platform",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#006833",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### **Service Worker**
- Cache static assets
- Offline fallback page
- Background sync for pending actions

---

## 🔌 API Integration Architecture

### **REST API Pattern**
```javascript
// services/api.js
const api = {
  async getVideos() {
    const snapshot = await getDocs(collection(db, 'videos'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  },
  
  async claimReward(type, amount) {
    const claimReward = httpsCallable(functions, 'claimReward');
    return await claimReward({ type, amount });
  }
};
```

---

## 🎯 Key Architecture Decisions Summary

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **Framework** | React 18 | Component-based, large ecosystem |
| **Build Tool** | Vite | Fast dev server, optimized builds |
| **Styling** | Tailwind CSS | Utility-first, responsive, maintainable |
| **State** | Zustand | Simple, lightweight, no boilerplate |
| **Routing** | React Router v6 | Standard, powerful, nested routes |
| **Backend** | Firebase | Already integrated, real-time sync |
| **Video** | react-youtube | Reliable YouTube embedding |
| **Real-time** | Firestore listeners | Built-in, scales well |
| **Streaming** | Agora Web SDK | Same as mobile, proven |
| **Forms** | react-hook-form | Performance, validation |
| **HTTP** | Axios | Interceptors, error handling |
| **Icons** | react-icons | Comprehensive, tree-shakeable |
| **Animations** | Framer Motion | Smooth, declarative |

---

**Next Steps**: Review WEB_APP_IMPLEMENTATION_PLAN.md for detailed step-by-step implementation instructions.
