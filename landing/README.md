# CoinNewsExtra TV — Landing

This is a small React + Vite single-page landing site for CoinNewsExtra TV.
It intentionally reuses the app's primary color (#006833) and references existing assets in the repo.

Quick local run

1. cd landing
2. npm install
3. npm run dev

Build

npm run build

This will produce `landing/dist` which can be served as static files.

Firebase hosting

The repository already has `firebase.json` for the Flutter web build. We added a second hosting configuration that can serve the landing site from `landing/dist`.

To deploy the landing site specifically (one way):

1. Install the Firebase CLI and login:
   npm install -g firebase-tools
   firebase login

2. Build the landing site:
   cd landing; npm run build

3. Deploy hosting for the landing target:
   # if you set up a hosting target called `landing` in your firebase project
   firebase deploy --only hosting:landing

Notes / images

- The app references images under `/assets/*` (for example `/assets/icons/logo48.png`). For production, make sure those assets are copied or available at the hosting root. Options:
  - Copy the `assets/` folder into `landing/dist/assets` as part of your build/publish step.
  - Or update the Firebase hosting config to serve the repository `assets/` directory as a public asset folder.

Next steps

- Replace placeholder text with final copy.
- Provide any hero images / screenshots to include in `landing/public/assets` or copy the repo assets into the built output.
- Optionally split sections into components and add animations / images.
