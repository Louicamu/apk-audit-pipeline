"use client";

import { useState, useRef, useEffect } from "react";
import { Send, GraduationCap, Atom, Loader2, Sparkles } from "lucide-react";

interface Message {
  role: "user" | "assistant";
  content: string;
}

const SUGGESTIONS = [
  "Explain band structure in semiconductors",
  "What are Frenkel defects?",
  "Summarize the properties of Graphene",
  "How do doping atoms change conductivity?",
];

export default function AIChat({ onQueryElement }: { onQueryElement?: (symbol: string) => void }) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      content:
        "Hello! I'm Professor Aris Tensor, your materials physics guide. Ask me about atomic structure, crystallography, band theory, lattice defects, or enter a chemical symbol (e.g., Au, Si) to visualize it. How can I help you learn today?",
    },
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  const sendMessage = async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed || loading) return;

    const userMsg: Message = { role: "user", content: trimmed };
    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setLoading(true);

    // Check if user typed a single element symbol
    const elementMatch = trimmed.match(/^(H|He|Li|Be|B|C|N|O|F|Ne|Na|Mg|Al|Si|P|S|Cl|Ar|K|Ca|Fe|Cu|Zn|Ag|Au|Pt|Pb|U)$/i);
    if (elementMatch && onQueryElement) {
      const symbol = elementMatch[1].charAt(0).toUpperCase() + elementMatch[1].slice(1).toLowerCase();
      onQueryElement(symbol);
    }

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: trimmed,
          history: messages.slice(-6).map((m) => ({ role: m.role, content: m.content })),
        }),
      });

      if (!res.ok) {
        throw new Error(`API returned ${res.status}`);
      }

      const data = await res.json();
      setMessages((prev) => [...prev, { role: "assistant", content: data.reply }]);
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            "Ah, it seems my neural pathways are experiencing some interference. Please try again in a moment — even quantum systems need decoherence time.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    sendMessage(input);
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center gap-3 p-4 border-b border-border">
        <GraduationCap className="w-5 h-5 text-[var(--accent-2)]" />
        <div>
          <h2 className="text-sm font-semibold text-foreground">AI Tutor</h2>
          <p className="text-xs text-zinc-500">Prof. Aris Tensor — Materials Physics</p>
        </div>
      </div>

      {/* Messages */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`flex gap-3 ${msg.role === "user" ? "flex-row-reverse" : ""}`}
          >
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                msg.role === "assistant"
                  ? "bg-[var(--accent-2)]/20"
                  : "bg-[var(--accent)]/20"
              }`}
            >
              {msg.role === "assistant" ? (
                <Atom className="w-4 h-4 text-[var(--accent-2)]" />
              ) : (
                <Sparkles className="w-4 h-4 text-[var(--accent)]" />
              )}
            </div>
            <div
              className={`max-w-[80%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                msg.role === "assistant"
                  ? "bg-surface border border-border text-foreground"
                  : "bg-[var(--accent)]/10 border border-[var(--accent)]/30 text-foreground"
              }`}
            >
              {msg.role === "assistant" ? (
                <AssistantMessage content={msg.content} />
              ) : (
                <p>{msg.content}</p>
              )}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex gap-3">
            <div className="w-8 h-8 rounded-full bg-[var(--accent-2)]/20 flex items-center justify-center">
              <Loader2 className="w-4 h-4 text-[var(--accent-2)] animate-spin" />
            </div>
            <div className="bg-surface border border-border rounded-2xl px-4 py-3">
              <div className="flex gap-1">
                <span className="w-2 h-2 bg-[var(--accent-2)] rounded-full animate-bounce" />
                <span className="w-2 h-2 bg-[var(--accent-2)] rounded-full animate-bounce [animation-delay:0.15s]" />
                <span className="w-2 h-2 bg-[var(--accent-2)] rounded-full animate-bounce [animation-delay:0.3s]" />
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Suggestions */}
      {messages.length <= 1 && (
        <div className="px-4 pb-2 flex flex-wrap gap-2">
          {SUGGESTIONS.map((s) => (
            <button
              key={s}
              onClick={() => sendMessage(s)}
              className="text-xs px-3 py-1.5 rounded-full bg-surface border border-border text-zinc-400 hover:text-foreground hover:border-zinc-600 transition-colors text-left"
            >
              {s}
            </button>
          ))}
        </div>
      )}

      {/* Input */}
      <form onSubmit={handleSubmit} className="p-4 border-t border-border">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask about materials science..."
            className="flex-1 bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-foreground placeholder:text-zinc-600 focus:outline-none focus:border-[var(--accent-2)] transition-colors"
            disabled={loading}
          />
          <button
            type="submit"
            disabled={loading || !input.trim()}
            className="px-4 py-2.5 rounded-xl bg-[var(--accent-2)] text-white disabled:opacity-40 hover:brightness-110 transition-all flex items-center gap-2"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </form>
    </div>
  );
}

function AssistantMessage({ content }: { content: string }) {
  const lines = content.split("\n");
  return (
    <div className="space-y-2">
      {lines.map((line, i) => {
        // Bold headers
        if (line.startsWith("**") && line.endsWith("**")) {
          return (
            <h4 key={i} className="font-semibold text-[var(--accent)] text-sm mt-2">
              {line.slice(2, -2)}
            </h4>
          );
        }
        // Bullet points
        if (line.startsWith("- ") || line.startsWith("• ")) {
          return (
            <p key={i} className="text-zinc-300 pl-2 text-sm">
              {line}
            </p>
          );
        }
        if (line.trim() === "") return <div key={i} className="h-1" />;
        return (
          <p key={i} className="text-sm text-zinc-300">
            {line}
          </p>
        );
      })}
    </div>
  );
}
