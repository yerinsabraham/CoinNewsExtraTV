# CoinNewsExtra TV - Web App Analysis

**Date**: December 9, 2025  
**Project**: CNE Watch2Earn Web Application  
**Current App**: Flutter (Mobile - Android/iOS)  
**Target**: React Web Application (Browser-based)

---

## 📱 Current Flutter App Overview

### **App Identity**
- **Name**: CNE Watch2Earn (CoinNewsExtra TV)
- **Type**: Watch-to-Earn Educational Platform
- **Blockchain**: Hedera Hashgraph Mainnet
- **Token**: CNE Token (ID: 0.0.9764298)
- **Backend**: Firebase (Auth, Firestore, Functions, Hosting, Messaging)
- **Authentication**: Firebase Auth + Google Sign-In
- **Real-time Database**: Cloud Firestore
- **Status**: Production Ready, APK available for Play Store

---

## 🎯 Core Features Analysis

### **1. Authentication & User Management**
**Current Implementation:**
- Firebase Authentication (Email/Password + Google Sign-In)
- User profile with display name, email, avatar
- Referral code system (700 CNE per referral)
- W3C DID integration for decentralized identity
- Profile persistence across sessions
- User data stored in Firestore `/users/{uid}`

**User Data Structure:**
```javascript
{
  uid: string,
  email: string,
  displayName: string,
  cneBalance: number,
  totalBalance: number,
  lockedBalance: number,
  unlockedBalance: number,
  totalEarnings: number,
  referralCode: string,
  hederaWallet: {
    accountId: string,
    publicKey: string,
    network: "mainnet"
  },
  createdAt: timestamp,
  lastUpdated: timestamp
}
```

---

### **2. CNE Token Reward System**

**Current Tier (1-10K Users):**

| Activity | CNE Reward | Frequency |
|----------|-----------|-----------|
| Signup Bonus | 700 CNE | One-time |
| Daily Check-in | 28 CNE | Daily |
| Referral | 700 CNE | Per referral |
| Video Watch | 7 CNE | Per video |
| Live TV Watch | 7 CNE | Per session |
| Quiz Answer (Correct) | 2 CNE | Per question |
| Social Media Follow | 100 CNE | Per platform (7 platforms) |
| Chat Message | 0.1 CNE | Per message |
| AI Consultation | 0.5 CNE | Per interaction |
| Spotlight View | 2.8 CNE | Per spotlight |
| Ad View | 2.8 CNE | Per ad |
| Spin2Earn | 0.5-1000 CNE | Random (5 spins/day) |

**Streak Bonuses:**
- 7-day streak: 196 CNE
- 30-day streak: 840 CNE

**Token Persistence:**
- Real-time Firestore synchronization
- Cross-session persistence (survives logout/login)
- Automatic balance recovery
- Never loses tokens

---

### **3. Content & Entertainment Features**

#### **A. Live TV Streaming**
- YouTube live stream integration
- Live chat with real-time Firestore updates
- Viewer count display
- Like/dislike functionality
- Live polls during streams
- Watch time tracking (reward after X minutes)
- 7 CNE reward per qualifying watch session

#### **B. Video Library (Watch & Earn)**
- 50+ curated crypto educational videos
- YouTube player integration
- Video categories: Bitcoin, Ethereum, DeFi, NFTs, Trading
- Progress tracking per video
- 7 CNE reward per video completion
- Watched status persistence
- Video details: title, description, thumbnail, duration, views

#### **C. Live Streaming (Agora RTC)**
- Real-time video/audio streaming
- Agora RTC engine integration
- Host/viewer roles
- Token-based authentication
- Channel management
- Background audio support
- Permission handling (camera, microphone)

---

### **4. Interactive Games & Earning**

#### **A. Quiz System**
- Multiple categories: Bitcoin, Ethereum, DeFi, NFTs, Altcoins, Trading, Blockchain
- 10 questions per quiz session
- 15-second timer per question
- 2 CNE per correct answer
- Difficulty levels: Easy, Medium, Hard
- Progress tracking in Firestore
- Daily attempt limits per category
- Real-time score calculation

**Quiz Data Structure:**
```javascript
{
  category: string,
  difficulty: string,
  questions: [{
    text: string,
    options: string[],
    correctAnswer: number,
    explanation: string
  }],
  completedAt: timestamp,
  score: number,
  tokensEarned: number
}
```

#### **B. Spin2Earn Wheel**
- Fortune wheel with 9 prize segments
- Weighted probability system
- Daily spin limit: 5 spins
- Prize range: 0.5 - 1000 CNE
- Prize breakdown:
  - 1000 CNE: 1% chance
  - 500 CNE: 4% chance
  - 200 CNE: 10% chance
  - 100 CNE: 20% chance
  - 50 CNE: 30% chance
  - 10 CNE: 5% chance
  - NFT prizes: 30% chance
- Spin state persistence
- Animation with physics

#### **C. Play Extra (Battle Game)**
- Real-time multiplayer battles
- CNE token staking
- Multiple battle rooms with different stakes
- Wheel-based winner selection
- Room types: Rookie (10-100 CNE), Pro (100-500 CNE), Elite (500-1000 CNE)
- Real-time player count
- Forfeit system with penalties
- Battle history tracking

---

### **5. Social & Community Features**

#### **A. Chat System**
- Global community chat
- Real-time message sync (Firestore)
- User avatars and display names
- Emoji picker integration
- 0.1 CNE reward per message
- System messages
- Online user count
- Message history (last 100 messages)
- Auto-scroll to latest

#### **B. Social Media Integration**
- 7 platforms: Twitter, Instagram, Facebook, YouTube, Telegram, Discord, TikTok
- 100 CNE reward per follow
- Verification via external link opening
- One-time reward per platform
- Status tracking in Firestore

---

### **6. AI Assistant (ExtraAI)**

**Capabilities:**
- Crypto knowledge Q&A
- OpenAI GPT integration
- Conversation history (persistent)
- Daily question limit: 10 questions
- 0.5 CNE reward per consultation
- Context-aware responses
- Typing indicator
- Message threading
- Local storage for offline access

**AI Service Features:**
- Trusted crypto sources
- Concise responses
- Educational focus
- Rate limiting
- Error handling

---

### **7. News & Market Data**

#### **A. Crypto News**
- Real-time crypto news feed
- Article categories
- External link integration
- Share functionality
- Bookmarking system
- Push notifications for breaking news

#### **B. Market Cap Page**
- Top 100 cryptocurrencies
- Real-time price data (CoinGecko API)
- Price change indicators (24h)
- Market cap rankings
- Search functionality
- Price charts
- Sorting options

#### **C. Explore Page**
- Content discovery
- Featured content carousel
- Trending topics
- Category browsing
- Personalized recommendations

---

### **8. Events & Scheduling**

#### **A. Summit Page**
- Crypto events calendar
- Event details: date, time, location, speakers
- Registration system
- Reminder notifications
- Event categories
- Past events archive

#### **B. Program Page**
- TV schedule for CNE TV
- Show details and descriptions
- Time slots
- Recurring programs
- Notification preferences

---

### **9. User Dashboard & Profile**

#### **A. Home Screen**
- Banner carousel (promotions, announcements)
- Quick access feature grid:
  - Live TV
  - Watch Videos
  - Quiz
  - Spin2Earn
  - Play Extra
  - Daily Check-in
  - Chat
  - ExtraAI
- Recent activity feed
- Balance display with USD conversion
- Notification badge

#### **B. Wallet Page**
- Total CNE balance display
- Locked vs Unlocked balance
- Transaction history
- Earning sources breakdown
- Hedera wallet info (Account ID, Public Key)
- Withdrawal options (future)
- Balance refresh

#### **C. Profile Page**
- User info: name, email, join date
- CNE balance summary
- Referral code sharing
- Total earnings stats
- Account settings
- Help & Support access
- Admin dashboard (for admins)
- Logout

---

### **10. Admin System**

**Admin Roles:**
- Super Admin (hardcoded emails)
- Content Admin
- Finance Admin
- Support Admin

**Admin Features:**
- User management (view, edit, delete users)
- Content management (videos, quizzes, spotlights)
- Finance tracking (rewards, withdrawals)
- Support ticket management
- App settings configuration
- Analytics dashboard
- Notification broadcasting

**Admin Screens:**
- Dashboard overview
- User management
- Content management
- Finance admin
- Support management
- Settings management
- Updates admin
- Spotlight management

---

### **11. Help & Support**

**Features:**
- Live video call support (Agora RTC)
- Chat support system
- Issue reporting with categories
- Support ticket tracking
- FAQ section
- Contact information
- Support history

**Issue Categories:**
- Technical issues
- Account problems
- Payment issues
- Content issues
- General inquiries

---

### **12. Notifications System**

**Types:**
- Push notifications (Firebase Cloud Messaging)
- In-app notifications
- Breaking news alerts
- Reward notifications
- Event reminders
- System announcements

**Features:**
- Notification settings page
- Read/unread status
- Notification history
- Badge counts
- Deep linking to content

---

### **13. Onboarding & Tutorial**

**Features:**
- Welcome screen (first launch)
- Interactive tutorial (Coach marks)
- Feature spotlights
- Guided tours for main features
- Skip option
- Never show again preference

---

## 🏗️ Technical Architecture (Current Flutter App)

### **Frontend**
- **Framework**: Flutter 3.24+
- **Language**: Dart
- **State Management**: Provider pattern
- **Navigation**: Named routes
- **UI Components**: Material Design
- **Video Player**: youtube_player_flutter
- **Real-time Streaming**: agora_rtc_engine
- **Animations**: Lottie, custom animations
- **Icons**: Feather Icons, Material Icons

### **Backend Services**
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Cloud Functions**: Firebase Functions (Node.js)
- **Storage**: Firebase Storage
- **Hosting**: Firebase Hosting
- **Messaging**: Firebase Cloud Messaging
- **Analytics**: Firebase Analytics
- **Remote Config**: Firebase Remote Config

### **Third-Party Integrations**
- **Blockchain**: Hedera Hashgraph SDK
- **AI**: OpenAI API (GPT)
- **Video Streaming**: Agora RTC
- **Market Data**: CoinGecko API
- **Social Login**: Google Sign-In
- **Payments**: (Future - Hedera transfers)

### **Data Storage**
- **Firestore Collections**:
  - `/users/{uid}` - User profiles and balances
  - `/videos/` - Video library
  - `/quizzes/{category}/questions` - Quiz questions
  - `/chat_messages/` - Global chat
  - `/ai_conversations/{uid}` - AI chat history
  - `/battles/{battleId}` - Play Extra battles
  - `/events/` - Summit events
  - `/spotlights/` - Featured content
  - `/admin_actions/` - Admin audit log
  - `/support_tickets/{ticketId}` - Support issues

---

## 📊 User Flow Summary

### **New User Journey**
1. Welcome screen → Signup (Email or Google)
2. Receive 700 CNE signup bonus
3. Interactive tutorial (optional)
4. Home dashboard with feature overview
5. First daily check-in → 28 CNE
6. Explore features and earn rewards

### **Daily Active User Journey**
1. Login → Daily check-in (28 CNE)
2. Watch videos → 7 CNE each
3. Complete quiz → 2 CNE per correct answer
4. Spin wheel → Random CNE
5. Chat participation → 0.1 CNE per message
6. Live TV watching → 7 CNE
7. Check market prices
8. Read crypto news
9. Engage with community

### **Engaged User Journey**
1. Daily activities above +
2. Play Extra battles → Win CNE
3. AI consultations → 0.5 CNE each
4. Referral sharing → 700 CNE per referral
5. Social media follows → 100 CNE each
6. Event registration
7. Support interactions

---

## 🎨 Design Language

### **Color Palette**
- **Primary**: #006833 (Green)
- **Secondary**: #00B359 (Light Green)
- **Background**: #000000 (Black), #1A1A1A (Dark Gray)
- **Text**: #FFFFFF (White), #CCCCCC (Light Gray)
- **Accent**: #FFD700 (Gold) for rewards
- **Error**: #FF3B30 (Red)
- **Success**: #34C759 (Green)

### **Typography**
- **Font Family**: Lato (Regular, Bold, Black)
- **Headings**: Bold, 20-28px
- **Body**: Regular, 14-16px
- **Captions**: Regular, 12-13px

### **UI Patterns**
- Dark theme throughout
- Card-based layouts
- Gradient backgrounds
- Rounded corners (12px standard)
- Shadow effects for depth
- Green accent for CTAs and rewards
- Gold for premium/rewards

---

## 🔐 Security Features

1. **Firebase Security Rules** (Firestore, Storage)
2. **Authentication required** for all user actions
3. **Server-side validation** for rewards (Cloud Functions)
4. **Rate limiting** on earning activities
5. **Admin role verification** for privileged actions
6. **Secure API key management** (not in client code)
7. **DID integration** for identity verification
8. **Hedera wallet** custodial model (server-side private keys)

---

## 📱 Platform-Specific Features (Mobile Only)

These features may need alternative implementations or omission in web:

1. **Push Notifications** - Web has limited push support
2. **Background Audio** - Different in web browsers
3. **Camera/Microphone Access** - Browser permissions needed
4. **Deep Linking** - Different web approach (URL routing)
5. **App Icons/Splash Screen** - Web uses PWA manifest
6. **Local Storage** - Web uses localStorage/IndexedDB
7. **Platform Channels** - N/A for web

---

## 🎯 Key Takeaways for Web Version

### **Must-Have Features**
✅ Authentication (Firebase)  
✅ CNE Token System  
✅ Video Library (YouTube embeds)  
✅ Live TV  
✅ Quiz System  
✅ Spin2Earn  
✅ Chat System  
✅ Wallet Display  
✅ Market Data  
✅ News Feed  
✅ Profile & Settings  

### **Features Requiring Adaptation**
🔄 Play Extra (WebSocket for real-time)  
🔄 Live Streaming (WebRTC - Agora Web SDK)  
🔄 Push Notifications (Web Push API or in-app only)  
🔄 ExtraAI (Same API, different UI)  
🔄 Admin Dashboard (Responsive web design)  

### **Optional/Future Features**
⏳ Mobile-specific animations (simplify for web)  
⏳ Platform-specific optimizations  
⏳ Offline mode (PWA with service workers)  

---

**Next Steps**: Review WEB_APP_ARCHITECTURE.md for technical stack decisions and WEB_APP_IMPLEMENTATION_PLAN.md for step-by-step build instructions.
