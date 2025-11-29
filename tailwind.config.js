module.exports = {
content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/javascript/**/*.css'
],
theme: {
    extend: {
        colors: {
        customBlue: '#7CADED', // カスタムカラーを定義
        },
    },
},
plugins: [],
}