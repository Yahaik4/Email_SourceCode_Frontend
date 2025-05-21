importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyDZo9hdASiCYYuVRNwnrm_Tsl-CMTXrNAk',
  appId: '1:389409259766:web:dd73da5706aa99d0a32cd7',
  messagingSenderId: '389409259766',
  projectId: 'emailapp-35b26',
  authDomain: 'emailapp-35b26.firebaseapp.com',
  storageBucket: 'emailapp-35b26.firebasestorage.app',
  measurementId: 'G-FPV0J1FKZN',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();
