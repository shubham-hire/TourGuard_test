# NearbyNow 🌎

![React](https://img.shields.io/badge/React-18.2.0-61DAFB?logo=react)
![Vite](https://img.shields.io/badge/Vite-4.3.0-646CFF?logo=vite)
![TypeScript](https://img.shields.io/badge/TypeScript-5.3.2-3178C6?logo=typescript)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

> Find cafes, parks, shops, and hotspots near you — live on an interactive map. Built with React Leaflet, OpenStreetMap, and Vite.

## ✨ Features

- 📍 Get current user location (with fallback)
- 🗺️ Interactive, mobile-friendly map with React Leaflet
- 📌 Dynamic nearby places plotted as custom markers
- 🛣️ Distance calculation to each place
- 🚀 PWA Ready (Install as app on mobile)
- 🎨 Smooth UX with loaders and error handling
- 📦 Clean feature-based folder structure

---

## 🛠 Built With

- [React 18](https://react.dev/)
- [Vite](https://vitejs.dev/)
- [TypeScript](https://www.typescriptlang.org/)
- [React-Leaflet](https://react-leaflet.js.org/)
- [Leaflet](https://leafletjs.com/)
- [Zustand](https://github.com/pmndrs/zustand) (optional global state)
- [Axios](https://axios-http.com/)
- [Vite PWA Plugin](https://vite-plugin-pwa.netlify.app/)

---

## 🚀 Getting Started

Clone this repository:

```bash
git clone https://github.com/Nuraj250/NearbyNow.git
cd Nearbynow
````

Install dependencies:

```bash
npm install
```

Run the development server:

```bash
npm run dev
```

Visit: [http://localhost:5173](http://localhost:5173)

---

## 🌳 Project Structure

```
src/
├── features/
│   ├── map/                # Map rendering + markers
│   ├── places/             # Places API and components
│   └── location/           # User location context and hook
├── shared/                 # Loader, helpers, constants
├── App.tsx
├── main.tsx
└── index.css
```

---

## ⚙️ Environment Variables

Create a `.env` file if you plan to use real APIs later:

```bash
VITE_API_BASE_URL=https://api.example.com
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

---

## 📦 Build for Production

```bash
npm run build
```

Preview production build locally:

```bash
npm run preview
```

---

## 🚀 Deployment

You can deploy it easily to **Vercel**, **Netlify**, or any static host:

1. Push your code to GitHub
2. Connect your repo to [Vercel](https://vercel.com/)
3. Set build command: `npm run build`
4. Set output directory: `dist`
5. Done! 🎉

---

## 📝 License

This project is licensed under the [MIT License](LICENSE).

---

## ❤️ Contributing

Pull requests are welcome! If you find a bug or have a feature request, feel free to open an issue.
