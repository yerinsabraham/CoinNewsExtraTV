import React, { useState, useEffect } from 'react'
import './styles.css'

const Logo = () => (
  <img className="logo" src="/assets/icons/app_icon.png" alt="CNE Logo" />
)

function Carousel({ images = [], interval = 3500 }) {
  const [index, setIndex] = useState(0)

  useEffect(() => {
    if (!images || images.length <= 1) return
    const t = setInterval(() => setIndex(i => (i + 1) % images.length), interval)
    return () => clearInterval(t)
  }, [images, interval])

  if (!images || images.length === 0) return null

  const prev = () => setIndex(i => (i - 1 + images.length) % images.length)
  const next = () => setIndex(i => (i + 1) % images.length)

  return (
    <div className="carousel">
      <div className="carousel-track">
        {images.map((src, i) => (
          <img
            key={src}
            src={src}
            alt={`slide-${i}`}
            className={`carousel-slide ${i === index ? 'active' : ''}`}
          />
        ))}
      </div>
      <button className="carousel-btn prev" onClick={prev} aria-label="Previous">‹</button>
      <button className="carousel-btn next" onClick={next} aria-label="Next">›</button>
      <div className="carousel-dots">
        {images.map((_, i) => (
          <button key={i} className={`dot ${i === index ? 'on' : ''}`} onClick={() => setIndex(i)} />
        ))}
      </div>
    </div>
  )
}

function Header() {
  const [menuOpen, setMenuOpen] = useState(false)
  return (
    <header className="site-header">
      <div className="container header-inner">
        <div className="brand">
          <Logo />
          <div className="brand-text">
            <h1>CoinNewsExtra TV</h1>
            <p className="tag">Watch. Play. Earn.</p>
          </div>
        </div>
        <nav className="nav">
          <a href="#features">Features</a>
          <a href="#games">Games</a>
          <a href="#quiz">Quiz</a>
          <a href="#events">Events</a>
          <a className="primary" href="#">Open App</a>
        </nav>

        {/* Mobile menu button (vertical 3-dot svg) and slide-in drawer */}
        <div className="mobile-menu">
          <button
            className="menu-btn"
            aria-label={menuOpen ? 'close navigation' : 'open navigation'}
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen(v => !v)}
          >
              {/* SVG vertical 3-dot (kebab) icon - larger/thicker for mobile visibility */}
              <svg className="kebab-icon" width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
                <circle cx="12" cy="6" r="2.6" fill="currentColor" />
                <circle cx="12" cy="12" r="2.6" fill="currentColor" />
                <circle cx="12" cy="18" r="2.6" fill="currentColor" />
              </svg>
          </button>

          {/* overlay */}
          {menuOpen && <div className="mobile-overlay" onClick={() => setMenuOpen(false)} />}

          {/* drawer */}
          <aside className={`mobile-drawer ${menuOpen ? 'open' : ''}`} role="dialog" aria-hidden={!menuOpen}>
            <nav className="mobile-drawer-nav">
              <a href="#features" onClick={() => setMenuOpen(false)}>Features</a>
              <a href="#games" onClick={() => setMenuOpen(false)}>Games</a>
              <a href="#quiz" onClick={() => setMenuOpen(false)}>Quiz</a>
              <a href="#events" onClick={() => setMenuOpen(false)}>Events</a>
              <a className="primary" href="#" onClick={() => setMenuOpen(false)}>Open App</a>
            </nav>
          </aside>
        </div>
      </div>
    </header>
  )
}

function Hero() {
  return (
    <section className="hero">
      <div className="container hero-inner">
        <div className="hero-copy">
          <h2>Live video, interactive games, quizzes & more</h2>
          <p>
            CoinNewsExtra TV is a watch-to-earn platform that streams live
            video, runs interactive games and quizzes, and lets brands advertise
            directly to engaged viewers.
          </p>
          <div className="hero-cta">
            <a className="btn" href="#features">Learn more</a>
            <a className="btn outline" href="#">Open app</a>
          </div>
        </div>
        <div className="hero-media">
          <Carousel images={[
            '/assets/spotlight/1.png',
            '/assets/spotlight/2.png',
            '/assets/spotlight/3.png',
            '/assets/spotlight/4.png'
          ]} />
        </div>
      </div>
    </section>
  )
}

function Feature({ title, text, icon }) {
  return (
    <div className="feature">
      <div className="feature-top">
        <div className="icon">{icon}</div>
        <h3>{title}</h3>
      </div>
      <p>{text}</p>
    </div>
  )
}

function FeaturesSection() {
  return (
    <section id="features" className="section">
      <div className="container">
        <h2 className="section-title">What the app does</h2>
        <div className="features-grid">
          <Feature
            icon={<span role="img" aria-label="video">🎥</span>}
            title="Live Video"
            text="Watch live streams, news shows, and interactive broadcasts with in-player rewards."
          />
          <Feature
            icon={<span role="img" aria-label="game">🎮</span>}
            title="Play & Win"
            text="Play real-time games and minigames for coins and rewards."
          />
          <Feature
            icon={<span role="img" aria-label="quiz">❓</span>}
            title="Quizzes"
            text="Take quizzes during shows to earn tokens and climb leaderboards."
          />
          <Feature
            icon={<span role="img" aria-label="calendar">📅</span>}
            title="Scheduled Events"
            text="Create or attend scheduled events and watch special broadcasts."
          />
          <Feature
            icon={<span role="img" aria-label="ad">📣</span>}
            title="Advertise"
            text="Brands can purchase ad inventory or sponsor events directly on the platform."
          />
          <Feature
            icon={<span role="img" aria-label="wallet">💼</span>}
            title="Wallet & Rewards"
            text="Integrated wallet for rewards, with token/points tracking."
          />
        </div>
      </div>
    </section>
  )
}

function GamesSection() {
  return (
    <section id="games" className="section alt">
      <div className="container">
        <h2 className="section-title">Games & Interactives</h2>
        <p className="lead">
          Fast, casual games integrated into streams — spin wheels, battles,
          and more. Players can compete for prizes live.
        </p>
        <div className="ad-sample">
          <img src="/assets/images/ad1.png" alt="Ad sample" />
          <div className="ad-desc">
            <h4>Sample Ad Placement</h4>
            <p>
              Ads can appear as banners, mid-roll cards, or branded game
              placements. We support images and rich creatives.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}

function QuizSection() {
  return (
    <section id="quiz" className="section">
      <div className="container quiz-inner">
        <div className="quiz-copy">
          <h2 className="section-title">Quizzes & Engagement</h2>
          <p>
            Host live quizzes, reward quick responders, and integrate leaderboards
            into your shows.
          </p>
        </div>
        <div className="quiz-media">
          <div className="quiz-emoji">🏆</div>
        </div>
      </div>
    </section>
  )
}

function EventsSection() {
  return (
    <section id="events" className="section alt">
      <div className="container">
        <h2 className="section-title">Events & Scheduling</h2>
        <p>
          Schedule live broadcasts and events. Users can RSVP, receive
          reminders, and join live when a show starts.
        </p>
      </div>
    </section>
  )
}

function AdvertiseSection() {
  return (
    <section id="advertise" className="section">
      <div className="container">
        <h2 className="section-title">Advertise with us</h2>
        <p>
          Reach engaged viewers through in-stream placements and sponsored
          events. Contact sales to get ad specs and pricing.
        </p>
      </div>
    </section>
  )
}

function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-inner">
        <div className="col">
          <h4>About</h4>
          <p>
            CoinNewsExtra TV is a platform combining live streaming, interactive
            games and rewards to keep audiences engaged.
          </p>
        </div>
        <div className="col">
          <h4>Info</h4>
          <ul>
            <li>Privacy</li>
            <li>Terms</li>
            <li>Support</li>
          </ul>
        </div>
        <div className="col">
          <h4>FAQ</h4>
          <ul>
            <li>How do I earn?</li>
            <li>How do I redeem rewards?</li>
          </ul>
        </div>
        <div className="col social">
          <h4>Follow</h4>
          <div className="social-icons">
            <img src="/assets/svgs/twitter.svg" alt="twitter" />
            <img src="/assets/svgs/instagram.svg" alt="instagram" />
            <img src="/assets/svgs/youtube.svg" alt="youtube" />
          </div>
        </div>
      </div>
      <div className="copyright">© {new Date().getFullYear()} CoinNewsExtra TV</div>
    </footer>
  )
}

export default function App() {
  return (
    <div className="site">
      <Header />
      <main>
        <Hero />
        <FeaturesSection />
        <GamesSection />
        <QuizSection />
        <EventsSection />
        <AdvertiseSection />
      </main>
      <Footer />
    </div>
  )
}
