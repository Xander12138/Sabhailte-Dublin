// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCOjm2n4rWipuZJk0rcAepwAggKMJxsAkM",
  authDomain: "city-disaster-375ce.firebaseapp.com",
  projectId: "city-disaster-375ce",
  storageBucket: "city-disaster-375ce.firebasestorage.app",
  messagingSenderId: "67576872973",
  appId: "1:67576872973:web:5a0bb78766a84a55c59544",
  measurementId: "G-YMH41GPYQV",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
export { app, analytics };
