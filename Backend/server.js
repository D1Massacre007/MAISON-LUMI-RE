require('dotenv').config();

const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');

const app = express();

/* =========================
   MIDDLEWARE
========================= */
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

/* =========================
   ROOT
========================= */
app.get("/", (_req, res) => {
    res.json({
        ok: true,
        message: "Maison Lumière API is running"
    });
});

/* =========================
   DATABASE POOL
========================= */
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || "3306"),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10
});

async function db(sql, params = []) {
    const [rows] = await pool.execute(sql, params);
    return rows;
}

/* =========================
   GEMINI
========================= */
const ai = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY
});

/* =========================
   CLEAN TEXT
========================= */
function cleanText(text = "") {
    return text
        .replace(/\*\*/g, '')
        .replace(/\*/g, '')
        .replace(/_/g, '')
        .replace(/`/g, '')
        .replace(/#{1,6}\s?/g, '')
        .replace(/•/g, '')
        .replace(/\n{3,}/g, '\n\n')
        .trim();
}

/* =========================
   CACHE
========================= */
let cachedCtx = null;
let cacheTime = 0;

async function getCtx() {
    const now = Date.now();

    if (cachedCtx && now - cacheTime < 30000) {
        return cachedCtx;
    }

    const [products, variants, policies, boutiques] = await Promise.all([
        db(`SELECT id, name, price, colors, sizes FROM products ORDER BY id`),
        db(`SELECT * FROM product_variants`),
        db(`SELECT policy_type, title, content FROM policies`),
        db(`SELECT city, address, phone FROM boutiques`)
    ]);

    cachedCtx = { products, variants, policies, boutiques };
    cacheTime = now;

    return cachedCtx;
}

/* =========================
   PRODUCT MATCHER
========================= */
function findProduct(ctx, message) {
    const msg = message.toLowerCase();
    return ctx.products.find(p =>
        msg.includes(p.name.toLowerCase())
    );
}

/* =========================
   SIMPLE QUERY CHECK
========================= */
function isSimpleQuery(message) {
    const msg = message.toLowerCase();

    return (
        msg.length < 80 &&
        (
            msg.includes("colors") ||
            msg.includes("price") ||
            msg.includes("stock") ||
            msg.includes("sizes") ||
            msg.includes("available")
        )
    );
}

/* =========================
   SYSTEM PROMPT
========================= */
function systemPrompt(ctx) {
    return `
You are Maison Lumière AI assistant.

RULES:
- Respond in plain text only
- No markdown symbols
- Be concise and elegant

PRODUCT DATA:
${JSON.stringify(ctx.products)}
`;
}

/* =========================
   CONVERSATION MEMORY
========================= */
async function getConversation(sessionId) {
    const rows = await db(
        `SELECT id FROM chat_conversations WHERE session_id = ?`,
        [sessionId]
    );

    if (rows.length) return rows[0].id;

    const result = await db(
        `INSERT INTO chat_conversations (session_id) VALUES (?)`,
        [sessionId]
    );

    return result.insertId;
}

async function saveMessage(sessionId, role, message) {
    const cid = await getConversation(sessionId);

    await db(
        `INSERT INTO chat_messages (conversation_id, role, message)
         VALUES (?, ?, ?)`,
        [cid, role, message]
    );
}

async function loadHistory(sessionId) {
    const cid = await getConversation(sessionId);

    return await db(
        `SELECT role, message
         FROM chat_messages
         WHERE conversation_id = ?
         ORDER BY id DESC
         LIMIT 8`,
        [cid]
    );
}

function formatHistory(rows) {
    return rows.reverse().map(r => ({
        role: r.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: r.message }]
    }));
}

/* =========================
   GEMINI CALL
========================= */
async function askGemini(message, sessionId, ctx) {
    const history = formatHistory(await loadHistory(sessionId));

    const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [
            ...history,
            { role: 'user', parts: [{ text: message }] }
        ],
        config: {
            systemInstruction: systemPrompt(ctx),
            temperature: 0.4,
            maxOutputTokens: 350
        }
    });

    return cleanText(response.text || "");
}

/* =========================
   CHAT ROUTE
========================= */
app.post('/api/chat', async (req, res) => {
    try {
        const { message, sessionId } = req.body;

        if (!message || !sessionId) {
            return res.status(400).json({
                success: false,
                error: "Missing message or sessionId"
            });
        }

        const ctx = await getCtx();

        await saveMessage(sessionId, 'user', message);

        const product = findProduct(ctx, message);

        let reply;

        if (isSimpleQuery(message) && product) {
            reply = `${product.name} price is ${product.price}. Colors: ${product.colors}`;
        } else {
            reply = await askGemini(message, sessionId, ctx);
        }

        reply = cleanText(reply);

        await saveMessage(sessionId, 'assistant', reply);

        res.json({
            success: true,
            response: reply
        });

    } catch (err) {
        console.error("CHAT ERROR:", err);

        res.status(500).json({
            success: false,
            error: "Server error"
        });
    }
});

/* =========================
   PRODUCTS
========================= */
app.get('/api/products', async (_req, res) => {
    try {
        const ctx = await getCtx();
        res.json({ success: true, products: ctx.products });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

/* =========================
   HEALTH (FIXED)
========================= */
app.get('/api/health', (_req, res) => {
    res.json({ ok: true });
});

/* =========================
   NEWSLETTER (MISSING FIX)
========================= */
app.post('/newsletter', async (req, res) => {
    try {
        const { firstName, lastName, email } = req.body;

        await db(
            `INSERT INTO newsletter_subscribers (first_name, last_name, email)
             VALUES (?, ?, ?)`,
            [firstName, lastName, email]
        );

        res.json({
            success: true,
            message: "Subscribed successfully"
        });

    } catch (err) {
        console.error(err);

        res.json({
            success: false,
            message: "Subscription failed"
        });
    }
});

/* =========================
   START SERVER
========================= */
const PORT = process.env.PORT || 3001;

app.listen(PORT, async () => {
    console.log(`Server running → http://localhost:${PORT}`);

    const ctx = await getCtx();
    console.log(`Products loaded: ${ctx.products.length}`);
});