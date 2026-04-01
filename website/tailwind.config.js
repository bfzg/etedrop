/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js,jsx,tsx}", "./docs/**/*.{html,md}"],
  theme: {
    extend: {
      colors: {
        brand: "#0052D9",
        primary: "#0052D9",
        primaryHover: "#0042B2",
      },
    },
  },
  plugins: [],
  corePlugins: {
    preflight: false, // 防止tailwindcss 和 ant 样式冲突
  },
};
