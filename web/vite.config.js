import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor chunks
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'firebase-vendor': ['firebase/app', 'firebase/auth', 'firebase/firestore', 'firebase/functions', 'firebase/database'],
          'ui-vendor': ['lucide-react', 'react-hot-toast', 'date-fns'],
          
          // Video player chunks (large dependencies)
          'video-players': ['react-player'],
          
          // Feature chunks
          'video-features': [
            './src/pages/videos/VideosPage.jsx',
            './src/pages/videos/VideoDetailPage.jsx',
            './src/components/videos/VideoPlayer.jsx',
            './src/services/video.service.js'
          ],
          'quiz-features': [
            './src/pages/quiz/QuizListPage.jsx',
            './src/pages/quiz/QuizPlayPage.jsx',
            './src/services/quiz.service.js'
          ],
          'chat-features': [
            './src/pages/chat/ChatPage.jsx',
            './src/services/chat.service.js'
          ],
          'admin-features': [
            './src/pages/admin/AdminDashboard.jsx',
            './src/services/admin.service.js'
          ]
        }
      }
    },
    chunkSizeWarningLimit: 1000,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom', 'firebase/app', 'firebase/auth', 'firebase/firestore']
  }
})
