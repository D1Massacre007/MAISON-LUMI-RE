# Maison Lumière — AI Concierge
 
A luxury e-commerce experience for a high-end leather goods maison, featuring an AI-powered concierge, bespoke order management, and a fully animated editorial frontend.
 
---
 
## Overview
 
Maison Lumière is a full-stack luxury retail platform built around an AI concierge that handles product discovery, bespoke consultations, and client services. The brand identity — dark editorial aesthetics, gold accents, Cormorant Garamond typography — is reflected across every layer of the interface.
 
The concierge is context-aware, drawing from live product inventory, boutique locations, store policies, and conversation history to give responses that feel like a trained sales associate, not a chatbot.
 
---
 
## Live Demo
 
| Layer     | Platform | URL                              |
|-----------|----------|----------------------------------|
| Frontend  | Vercel   | `https://maisonlumiere.vercel.app` |
| Backend   | Render   | `https://maisonlumiere-api.onrender.com` |
| Database  | Railway  | MySQL instance (private)         |
 
---
 
## Tech Stack
 
### Frontend
- **Vanilla HTML / CSS / JavaScript** — no framework, hand-crafted for performance
- **GSAP 3** + ScrollTrigger — scroll-driven parallax, hero animations, staggered reveals
- **Cormorant Garamond** + **Jost** via Google Fonts — editorial typography pairing
- **CSS custom properties** — full design token system (ink, gold, cream, stone palette)
- **Vercel** — static hosting with global CDN
### Backend
- **Node.js** with **Express** — REST API server
- **mysql2** — promise-based MySQL driver with connection pooling
- **dotenv** — environment variable management
- **cors** — cross-origin support for Vercel → Render requests
- **Render** — backend hosting with auto-deploy from GitHub
### Database
- **MySQL** — relational database hosted on Railway
- **Tables:** `products`, `product_variants`, `chat_conversations`, `chat_messages`, `bespoke_orders`, `newsletter_subscribers`, `boutiques`, `policies`
- 30-second server-side cache layer for product/policy context to minimise DB round-trips
### AI
- **Google Gemini 2.5 Flash** via `@google/genai` SDK
- Routed entirely through the backend — the API key is never exposed to the client
- Temperature 0.4, max 350 tokens — tuned for concise, elegant responses
---
 
## AI Assistant
 
The heart of the platform is a luxury retail concierge powered by Gemini 2.5 Flash. It is designed to feel like a knowledgeable Maison associate — not a generic assistant.
 
### How It Works
 
Every chat request goes through three stages on the server:
 
**1. Context Assembly**
Before the AI is called, the server fetches a live snapshot of the database — products, variants, boutique details, and store policies — and injects it directly into the system prompt. This snapshot is cached for 30 seconds to avoid redundant DB queries on busy sessions. The AI therefore always knows current pricing, stock availability, colour options, and return/shipping terms without needing to call any external tool.
 
**2. Conversation Memory**
Each browser session generates a unique `sessionId`. Every user message and assistant reply is stored in MySQL under `chat_conversations` and `chat_messages`. On each new request, the server loads the last 8 messages for that session and formats them into Gemini's native multi-turn `contents` array. This gives the concierge short-term memory — it remembers what was discussed earlier in the conversation without bloating the context window.
 
**3. Response Generation**
The assembled history, the user's new message, and the system prompt (containing live store data) are sent to Gemini in a single `generateContent` call. The response is then stripped of all markdown symbols before being returned to the client, keeping the tone clean and editorial.
 
### System Prompt Design
 
The system prompt enforces three rules:
- Respond in plain text only — no markdown, no bullet points
- Be concise and elegant — short answers in keeping with luxury brand voice
- Use only the injected product and policy data — no hallucinated prices or specs
### Fast-Path for Simple Queries
 
To reduce unnecessary AI calls, the server checks whether the message is a short product query (under 80 characters, asking about price, colours, stock, or sizes). If a matching product is found by name in the message, a templated reply is returned instantly without calling Gemini at all.
 
### What the Concierge Knows
 
| Data Source         | Detail                                                      |
|---------------------|-------------------------------------------------------------|
| Products            | Names, SKUs, prices, descriptions, materials, crafting time |
| Variants            | Per-colour and per-size stock quantities                    |
| Boutiques           | Addresses, phone numbers, cities (Paris, Milan, NYC, Tokyo) |
| Policies            | Return window, shipping terms, repair service, monogramming |
| Conversation history| Last 8 turns per session, persisted in MySQL                |
 
### Example Interactions
 
> "What colours does Le Grand Sac come in?"
> → Returns the three variants (Black, Cognac, Ivory) with current stock per colour.
 
> "Can I return a monogrammed bag?"
> → Correctly states that bespoke and monogrammed pieces are final sale, drawn from the policies table.
 
> "Tell me about your repair service."
> → Describes the lifetime repair programme at the Florence atelier from the care and repair policy.
 
> "I'd like a custom bag in burgundy python with gold hardware."
> → Acknowledges the bespoke request and directs the client to the consultation form.
 
---
 
## Features
 
- **AI Concierge Chat** — persistent per-session conversation history, product-aware, policy-aware
- **Product Catalogue** — 5 hero pieces with colour/size variants, live stock quantities
- **Bespoke Order Flow** — custom leather, hardware, monogram, and consultation request capture
- **Newsletter Subscription** — first name, last name, email stored to MySQL
- **Boutique Locator** — Paris, Milan, New York, Tokyo with hours and contact details
- **Scroll Animations** — GSAP parallax on hero, about, collection, and statement sections
- **Velocity Marquee** — physics-based dual-column scroll-reactive word marquee
- **Loader** — branded percentage loader on first visit
---
 
## Project Structure
 
```
maison-lumiere/
├── index.html          # Full frontend — single file, all CSS + JS inline
├── server.js           # Express API server
├── database.sql        # Schema + seed data
├── package.json
├── .env.example        # Environment variable template (no secrets)
├── .gitignore
└── README.md
```
 
---
 
## Environment Variables
 
Create a `.env` file in the project root. This file is not committed — never share these values publicly.
 
```env
PORT=3001
 
DB_HOST=
DB_PORT=3306
DB_USER=
DB_PASSWORD=
DB_NAME=
 
GEMINI_API_KEY=
```
 
---
 
## Getting Started
 
### Prerequisites
- Node.js 18+
- A running MySQL instance (local or Railway)
- A Google Gemini API key
### Setup
 
```bash
# 1. Clone the repo
git clone https://github.com/yourusername/maisonlumiere.git
cd maisonlumiere
 
# 2. Install dependencies
npm install
 
# 3. Set up environment variables
cp .env.example .env
# fill in your DB credentials and Gemini API key
 
# 4. Initialise the database
mysql -u root -p < database.sql
 
# 5. Start the dev server
npm run dev
```
 
The server starts at `http://localhost:3001` and serves `index.html` as a static file.
 
---
 
## API Endpoints
 
| Method | Route            | Description                              |
|--------|------------------|------------------------------------------|
| POST   | `/api/chat`      | Send a message to the AI concierge       |
| GET    | `/api/products`  | Fetch all products (cached 30s)          |
| POST   | `/newsletter`    | Subscribe to the newsletter              |
| GET    | `/api/health`    | Health check                             |
 
### Chat request body
```json
{
  "message": "What colours does Le Grand Sac come in?",
  "sessionId": "uuid-per-browser-session"
}
```
 
---
 
## Database Schema
 
| Table                   | Purpose                                      |
|-------------------------|----------------------------------------------|
| `products`              | Master product catalogue with pricing        |
| `product_variants`      | Colour + size combinations with stock levels |
| `chat_conversations`    | Session-keyed conversation threads           |
| `chat_messages`         | Individual user and assistant messages       |
| `bespoke_orders`        | Custom commission enquiries                  |
| `newsletter_subscribers`| Email capture for editorial newsletters      |
| `boutiques`             | Store locations, hours, and contact info     |
| `policies`              | Return, shipping, repair, and monogram terms |
 
---
 
## Deployment
 
### Backend — Render
1. Push to GitHub
2. Create a new **Web Service** on Render, connect the repo
3. Set build command: `npm install`
4. Set start command: `node server.js`
5. Add all environment variables from `.env` in the Render dashboard
### Database — Railway
1. Create a new **MySQL** service on Railway
2. Copy the connection credentials into your Render environment variables
3. Run `database.sql` against the Railway instance to initialise schema and seed data
### Frontend — Vercel
1. Import the repo into Vercel
2. Set the **Output Directory** to `.` (root)
3. Set the **Framework Preset** to `Other`
4. Add an environment variable or hardcode the Render backend URL in `index.html` where the fetch calls point to `/api/chat`
---
 
## Design System
 
| Token     | Value     | Usage                        |
|-----------|-----------|------------------------------|
| `--ink`   | `#0c0b09` | Primary background           |
| `--deep`  | `#111009` | Deepest background layer     |
| `--coal`  | `#1a1814` | Secondary surface            |
| `--stone` | `#7a756e` | Subdued body text            |
| `--cream` | `#f0ebe1` | Primary text                 |
| `--gold`  | `#b89660` | Brand accent                 |
| `--gold2` | `#d4b47a` | Hover / highlight gold       |
 
Typography: **Cormorant Garamond** (serif, editorial headings) + **Jost** (sans-serif, UI labels and body copy).
 
---
 
## Licence
 
This project is licensed under the [MIT License](LICENSE).
 
