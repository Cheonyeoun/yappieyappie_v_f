const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

// Ensure Firebase is initialized only once
if (getApps().length === 0) {
  try {
    // Vercel environment variables securely store the service account JSON
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    initializeApp({
      credential: cert(serviceAccount),
    });
  } catch (error) {
    console.error("Firebase initialization error:", error);
  }
}

module.exports = async function handler(req, res) {
  // CORS configuration
  res.setHeader("Access-Control-Allow-Credentials", true);
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET,OPTIONS,PATCH,DELETE,POST,PUT"
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version"
  );

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { receiverId, chatId, messageId, type } = req.body;

  if (!receiverId || !chatId || !messageId) {
    return res.status(400).json({ error: "Missing receiverId, chatId, or messageId" });
  }

  try {
    // 1. Fetch the receiver's tokens and PRESENCE status
    const userDoc = await getFirestore().collection("users").doc(receiverId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: "User not found" });
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens || [];

    if (fcmTokens.length === 0) {
      return res.status(200).json({ success: true, message: "No FCM tokens found." });
    }

    // SUPPRESSION CHECK (Presence Aware)
    if (userData.isOnline === true && userData.currentChatId === chatId) {
      console.log(`User ${receiverId} is active in chat ${chatId}. Suppressing push notification.`);
      return res.status(200).json({ success: true, message: "User is actively in chat, suppressing push." });
    }

    // 2. Fetch the sender details for the Notification payload (Abstract / Privacy-preserving)
    let title = "New Message";
    let body = "Sent you a new message 🔒";
    
    // Get sender's name from the message
    const messageDoc = await getFirestore().collection("chats").doc(chatId).collection("messages").doc(messageId).get();
    if (messageDoc.exists) {
      const msgData = messageDoc.data();
      const senderId = msgData.senderId;
      if (senderId) {
        const senderDoc = await getFirestore().collection("users").doc(senderId).get();
        if (senderDoc.exists) {
          title = senderDoc.data().name || title;
        }
      }
    }

    // 3. Construct the Native OS Notification payload
    const messagePayload = {
      tokens: fcmTokens,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type || "text",
        chatId: chatId,
        messageId: messageId,
      },
      android: {
        priority: "high", // Guarantees instant wake up from Doze mode
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await getMessaging().sendEachForMulticast(messagePayload);
    console.log("Successfully sent message:", response);

    return res.status(200).json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error) {
    console.error("Error sending message:", error);
    return res.status(500).json({ error: "Failed to send message" });
  }
}
