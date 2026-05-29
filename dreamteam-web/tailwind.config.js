/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/client/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        pitch: "#1f6f3a",
        pitchDark: "#16562d",
        // LabLogic brand palette (https://lablogic.com)
        brand: {
          navy: "#06213E",
          navyDark: "#04162a",
          navyMid: "#1a334d",
          cyan: "#1EADDE",
          cyanDark: "#1490bb",
          slate: "#384d65",
          grey: "#4D4D4D",
          lightGrey: "#EDEDED",
        },
      },
    },
  },
  plugins: [],
};
