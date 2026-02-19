# CoinNewsExtra TV - Web Application

A React-based web application for watching crypto educational videos, reading news, and earning CNE tokens.

## Features

- 🎥 **Watch Videos**: Earn tokens by watching educational cryptocurrency content
- 📰 **Read News**: Stay updated with the latest crypto news and market insights
- 💰 **Earn Tokens**: Get rewarded with CNE tokens for engaging with content
- 👛 **Wallet Management**: Manage your CNE tokens and Hedera account
- 👤 **User Profiles**: Track your activity and earnings

## Tech Stack

- **React 19** - UI framework
- **Vite** - Build tool
- **React Router** - Navigation
- **Zustand** - State management
- **Firebase** - Authentication & database
- **Tailwind CSS** - Styling
- **Framer Motion** - Animations
- **React Hot Toast** - Notifications

## Getting Started

### Prerequisites

- Node.js 18+ and npm

### Installation

1. Clone the repository
```bash
git clone https://github.com/yerinsabraham/CoinNewsExtraTV.git
cd CoinNewsExtraTV/web
```

2. Install dependencies
```bash
npm install
```

3. Create a `.env` file in the web directory with your Firebase configuration:
```env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_auth_domain
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_storage_bucket
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
VITE_FIREBASE_MEASUREMENT_ID=your_measurement_id
```

4. Run the development server
```bash
npm run dev
```

5. Open [http://localhost:5173](http://localhost:5173) in your browser

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## Project Structure

```
web/
├── src/
│   ├── components/      # Reusable UI components
│   │   └── layout/      # Layout components
│   ├── pages/           # Page components
│   ├── store/           # Zustand stores
│   ├── lib/             # Utilities and Firebase config
│   ├── App.jsx          # Main app component
│   ├── main.jsx         # Entry point
│   └── index.css        # Global styles
├── public/              # Static assets
├── index.html           # HTML template
└── package.json         # Dependencies
```

## License

Copyright © 2026 CoinNewsExtra TV. All rights reserved.
