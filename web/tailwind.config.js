/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
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
  plugins: [],
}
