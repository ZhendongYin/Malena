/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "../lib/**/*.{ex,exs}",
    "../lib/**/*.heex",
    "../lib/**/*.eex",
    "../lib/**/*.leex",
    "../lib/**/*.js",
    "../lib/**/*.ts",
    "./js/**/*.js",
    "./css/**/*.css"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('daisyui'),
    require('./vendor/heroicons.js')
  ],
  daisyui: {
    themes: ["light", "dark"],
  },
}
