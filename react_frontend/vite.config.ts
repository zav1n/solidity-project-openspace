import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
// import path from 'path';

// https://vite.dev/config/
export default defineConfig({
  server: {
    port: 8866,
    // proxy: {
    //   "/relay": {
    //     target: "https://relay-sepolia.flashbots.net",
    //     changeOrigin: true,
    //     secure: true,
    //     rewrite: (path) => path.replace(/^\/relay/, "")
    //   }
    // }
  },
  plugins: [react()]
  // resolve: {
  //   alias: {
  //     "@": path.resolve(__dirname, "src")
  //   }
  // }
});
