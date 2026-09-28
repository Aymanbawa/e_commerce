import { defineConfig } from "vite";
export default defineConfig({
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  publicDir: false,
  build: {
    outDir: "public/static",
    emptyOutDir: false,
    lib: {
      entry: "src/client/main.tsx",
      formats: ["es"],
      fileName: () => "app.js",
      cssFileName: "app",
    },
    rollupOptions: { output: { assetFileNames: "[name].[ext]" } },
  },
});
