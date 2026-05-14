# AtomAI — Interactive Materials Science Learning Platform

**DSH Hacks V1 | AI x STEM Track**

AtomAI transforms abstract materials physics concepts into interactive visual experiences. Explore atomic structures with real-time 3D rendering, and learn from an AI professor who explains everything from band theory to perovskite solar cells.

## Tech Stack

- **Next.js 16** — App Router, React Server Components, API Routes
- **Tailwind CSS v4** — Utility-first styling with custom cyberpunk theme
- **Lucide React** — Beautiful, consistent iconography
- **TypeScript** — Type-safe across the entire codebase

## Quick Start

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Features

### Interactive Atom Viewer
- Real-time atomic structure rendering with animated electron orbits
- Supports H, He, Li, C, O, Na, Si, Fe, Cu, Au (extensible)
- Proton/neutron/electron counts displayed
- Random element explorer

### AI Materials Physics Professor
- Professor "Aris Tensor" persona with deep materials science knowledge
- Covers: band structure, crystal defects, graphene, doping, perovskites, superconductors, quantum dots
- Recognizes chemical symbols and auto-generates element summaries
- Suggested questions for quick exploration
- Smart topic detection from natural language queries

### GPU-Ready Architecture
- Modular design with placeholder for GPU-accelerated DFT/MD simulations
- API route pattern can be extended to call local LLMs (Ollama, llama.cpp) or cloud APIs

## Project Structure

```
atomai/
├── src/
│   ├── app/
│   │   ├── api/chat/route.ts    # AI tutor API (knowledge base + response generation)
│   │   ├── globals.css           # Cyberpunk theme with custom animations
│   │   ├── layout.tsx            # Root layout with metadata
│   │   └── page.tsx              # Main dashboard (split-view)
│   └── components/
│       ├── AtomViewer.tsx        # Interactive atom visualization
│       └── AIChat.tsx            # AI professor chat interface
├── public/                       # Static assets
├── package.json
└── tsconfig.json
```

## Real-World Impact

Materials science underpins every technological revolution — from silicon chips to battery technology, from carbon fiber to quantum computers. Yet most students encounter it only through static textbook diagrams. AtomAI bridges the gap between abstract theory and intuitive understanding, making advanced concepts accessible through visualization and natural conversation.

## License

MIT — Built for DSH Hacks V1
