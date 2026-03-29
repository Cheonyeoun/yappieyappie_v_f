require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const API_KEY = process.env.ONESIGNAL_API_KEY;

const validateRequest = (req, res, next) => {
  const { playerId, messages, unreadCount } = req.body;
  if (!playerId || !messages || unreadCount === undefined) {
    return res.status(400).json({ error: "Missing fields" });
  }
  next();
};

app.post("/send-notification", validateRequest, async (req, res) => {
  const { playerId, messages, chatRoomId, unreadCount } = req.body;

  try {
    let contentsText = "";

    // 8+ Logic: Summarize if count is high, otherwise list the stack
    if (unreadCount >= 8) {
      contentsText = `${unreadCount} new messages`;
    } else {
      messages.forEach((msg) => {
        contentsText += `${msg.senderName}: ${msg.text}\n`;
      });
    }

    const lastMsg = messages[messages.length - 1];
    const profileImg = lastMsg?.profileImg || "";

    const response = await axios.post(
      "https://onesignal.com/api/v1/notifications",
      {
        app_id: ONESIGNAL_APP_ID,
        include_player_ids: [playerId],
        headings: { en: lastMsg?.senderName || "New Message" },
        contents: { en: contentsText.trim() },
        
        // --- UX FIX: OVERWRITE PREVIOUS BUBBLE ---
        collapse_id: chatRoomId, 
        
        // --- GROUPING LOGIC ---
        thread_id: chatRoomId,
        android_group: chatRoomId,

        large_icon: profileImg,
        ios_attachments: { "id": profileImg },
        priority: 10,
        android_visibility: 1
      },
      {
        headers: {
          Authorization: `Basic ${API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    return res.json({ success: true });
  } catch (error) {
    console.error("OneSignal Error:", error.response?.data || error.message);
    return res.status(500).json({ success: false });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));