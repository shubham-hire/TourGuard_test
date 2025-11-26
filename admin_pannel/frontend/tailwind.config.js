/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                // Extracted from screenshot
                navy: {
                    DEFAULT: '#1e293b',
                    dark: '#0f172a',
                    light: '#334155',
                },
                danger: {
                    DEFAULT: '#ef4444',
                    light: '#f87171',
                    dark: '#dc2626',
                },
                success: {
                    DEFAULT: '#10b981',
                    light: '#34d399',
                    dark: '#059669',
                },
                warning: {
                    DEFAULT: '#f59e0b',
                    light: '#fbbf24',
                    dark: '#d97706',
                },
                info: {
                    DEFAULT: '#3b82f6',
                    light: '#60a5fa',
                    dark: '#2563eb',
                },
            },
            fontFamily: {
                sans: ['Inter', 'system-ui', 'sans-serif'],
            },
            boxShadow: {
                'glow-red': '0 0 20px rgba(239, 68, 68, 0.5)',
            },
            animation: {
                'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'bounce-subtle': 'bounce 2s infinite',
            },
        },
    },
    plugins: [],
}
