import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const API_KEY = process.env.GEMINI_API_KEY;

// CHAT endpoint
app.post("/chat", async (req, res) => {
  try {
    const { message } = req.body;

    // Google Gemini v1 endpointine DIREKT istek (gemini-pro modeli)
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${API_KEY}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              role: "user",
              parts: [{ text: message }],
            },
          ],
        }),
      }
    );

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error("Gemini hata:", geminiResponse.status, errorText);
      return res
        .status(500)
        .json({ error: "Gemini'den cevap alınamadı.", details: errorText });
    }

    const data = await geminiResponse.json();

    const reply =
      data.candidates?.[0]?.content?.parts?.[0]?.text ||
      "Herhangi bir cevap alamadım.";

    res.json({ reply });
  } catch (error) {
    console.error("Sunucu hatası:", error);
    res.status(500).json({ error: "Sunucu hatası oluştu." });
  }
});

// Tüm IP'lerden erişim
app.listen(3000, "0.0.0.0", () => {
  console.log("Server çalışıyor! Port:3000");
});
