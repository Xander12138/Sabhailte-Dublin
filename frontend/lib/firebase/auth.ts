// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

// Initialize Firebase
const app = initializeApp({
  apiKey: "AIzaSyD9aJVgoh5ZF_wcVS7V0XIdqCl3_PcJyDw",
  appId: "1:914170332121:web:69f7d2dd1eb24fbbed0fc8",
  messagingSenderId: "914170332121",
  projectId: "sabhailte-dublin",
  authDomain: "sabhailte-dublin.firebaseapp.com",
  storageBucket: "sabhailte-dublin.firebasestorage.app",
  measurementId: "G-JXJ5VHYSE9",
});

export const auth = getAuth(app);
