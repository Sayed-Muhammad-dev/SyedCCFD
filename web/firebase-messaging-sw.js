importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBN16_X7t74Sexzj2Whrd2MAs2PUcdHS7E",
  authDomain: "ccfd-616af.firebaseapp.com",
  projectId: "ccfd-616af",
  messagingSenderId: "519390265229",
  appId: "1:519390265229:web:5129889402a4405977c7c4",
  measurementId: "G-W0RKCZZ4VE"
});

const messaging = firebase.messaging();

// Optional: show a notification when a background message arrives
messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    data: payload.data || {}
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
