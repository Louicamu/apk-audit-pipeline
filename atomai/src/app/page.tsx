"use client";

import { useState } from "react";
import { Atom, Cpu } from "lucide-react";
import AtomViewer from "@/components/AtomViewer";
import AIChat from "@/components/AIChat";

export default function Home() {
  const [activeElement, setActiveElement] = useState("Au");

  return (
    <div className="h-screen flex flex-col">
      {/* Top nav bar */}
      <header className="h-14 flex items-center justify-between px-6 border-b border-border bg-surface/50 backdrop-blur flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[var(--accent)] to-[var(--accent-2)] flex items-center justify-center">
            <Atom className="w-5 h-5 text-white" />
          </div>
          <span className="text-lg font-bold text-foreground tracking-tight">
            Atom<span className="text-[var(--accent)]">AI</span>
          </span>
          <span className="text-xs text-zinc-600 hidden sm:inline font-mono">|</span>
          <span className="text-xs text-zinc-500 hidden sm:inline">Interactive Materials Science</span>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface border border-border text-xs text-zinc-400">
            <Cpu className="w-3.5 h-3.5 text-[var(--accent)]" />
            <span>GPU Simulation Ready</span>
          </div>
        </div>
      </header>

      {/* Main content: split view */}
      <div className="flex-1 flex flex-col lg:flex-row min-h-0">
        {/* Left: Atom Viewer */}
        <div className="flex-1 min-h-0 border-b lg:border-b-0 lg:border-r border-border">
          <AtomViewer key={activeElement} />
        </div>

        {/* Right: AI Chat */}
        <div className="w-full lg:w-[420px] xl:w-[480px] flex-shrink-0 min-h-0 h-[45vh] lg:h-full">
          <AIChat onQueryElement={(symbol) => setActiveElement(symbol)} />
        </div>
      </div>
    </div>
  );
}
