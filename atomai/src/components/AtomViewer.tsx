"use client";

import { useState, useCallback, useEffect } from "react";
import { Atom, Zap, RefreshCw } from "lucide-react";

interface ElectronShell {
  radius: number;
  electrons: number;
  speed: number;
  direction: "normal" | "reverse";
}

const ELEMENT_DATA: Record<string, { name: string; shells: ElectronShell[]; protons: number; neutrons: number; color: string }> = {
  H: { name: "Hydrogen", shells: [{ radius: 60, electrons: 1, speed: 8, direction: "normal" }], protons: 1, neutrons: 0, color: "#00d4ff" },
  He: { name: "Helium", shells: [{ radius: 60, electrons: 2, speed: 10, direction: "reverse" }], protons: 2, neutrons: 2, color: "#7c3aed" },
  Li: { name: "Lithium", shells: [{ radius: 50, electrons: 2, speed: 8, direction: "normal" }, { radius: 90, electrons: 1, speed: 12, direction: "reverse" }], protons: 3, neutrons: 4, color: "#f43f5e" },
  C: { name: "Carbon", shells: [{ radius: 50, electrons: 2, speed: 8, direction: "normal" }, { radius: 90, electrons: 4, speed: 10, direction: "reverse" }], protons: 6, neutrons: 6, color: "#22d3ee" },
  O: { name: "Oxygen", shells: [{ radius: 50, electrons: 2, speed: 9, direction: "normal" }, { radius: 90, electrons: 6, speed: 11, direction: "reverse" }], protons: 8, neutrons: 8, color: "#ef4444" },
  Na: { name: "Sodium", shells: [{ radius: 45, electrons: 2, speed: 7, direction: "normal" }, { radius: 75, electrons: 8, speed: 10, direction: "reverse" }, { radius: 110, electrons: 1, speed: 14, direction: "normal" }], protons: 11, neutrons: 12, color: "#fbbf24" },
  Si: { name: "Silicon", shells: [{ radius: 45, electrons: 2, speed: 7, direction: "normal" }, { radius: 75, electrons: 8, speed: 10, direction: "reverse" }, { radius: 110, electrons: 4, speed: 12, direction: "normal" }], protons: 14, neutrons: 14, color: "#a78bfa" },
  Fe: { name: "Iron", shells: [{ radius: 45, electrons: 2, speed: 7, direction: "normal" }, { radius: 70, electrons: 8, speed: 9, direction: "reverse" }, { radius: 95, electrons: 14, speed: 11, direction: "normal" }, { radius: 120, electrons: 2, speed: 14, direction: "reverse" }], protons: 26, neutrons: 30, color: "#f97316" },
  Au: { name: "Gold", shells: [{ radius: 42, electrons: 2, speed: 6, direction: "normal" }, { radius: 65, electrons: 8, speed: 8, direction: "reverse" }, { radius: 85, electrons: 18, speed: 10, direction: "normal" }, { radius: 105, electrons: 32, speed: 12, direction: "reverse" }, { radius: 125, electrons: 18, speed: 14, direction: "normal" }, { radius: 145, electrons: 1, speed: 16, direction: "reverse" }], protons: 79, neutrons: 118, color: "#fbbf24" },
};

const ORBIT_STYLE: Record<string, string> = {
  normal: "animate-orbit",
  reverse: "animate-orbit-reverse",
};

export default function AtomViewer() {
  const [formula, setFormula] = useState("Au");
  const [element, setElement] = useState(ELEMENT_DATA["Au"]);
  const [error, setError] = useState("");

  const parseFormula = useCallback((input: string) => {
    const cleaned = input.trim();
    if (!cleaned) {
      setError("Enter a chemical symbol (e.g., H, He, Fe, Au)");
      return;
    }
    const match = cleaned.match(/^([A-Z][a-z]?)(\d*)$/);
    if (!match) {
      setError("Unrecognized format. Use symbols like H, He, Na, Fe, Au");
      return;
    }
    const symbol = match[1];
    const data = ELEMENT_DATA[symbol];
    if (!data) {
      setError(`"${symbol}" not in demo database. Try H, He, Li, C, O, Na, Si, Fe, Au`);
      return;
    }
    setError("");
    setElement(data);
  }, []);

  useEffect(() => {
    parseFormula("Au");
  }, [parseFormula]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    parseFormula(formula);
  };

  const handleRandom = () => {
    const symbols = Object.keys(ELEMENT_DATA);
    const random = symbols[Math.floor(Math.random() * symbols.length)];
    setFormula(random);
    parseFormula(random);
  };

  return (
    <div className="flex flex-col h-full">
      {/* Controls */}
      <div className="flex items-center gap-3 p-4 border-b border-border">
        <Atom className="w-5 h-5 text-[var(--accent)]" />
        <form onSubmit={handleSubmit} className="flex items-center gap-2">
          <input
            type="text"
            value={formula}
            onChange={(e) => setFormula(e.target.value)}
            className="bg-surface border border-border rounded-lg px-3 py-1.5 text-sm font-mono text-foreground w-24 focus:outline-none focus:border-[var(--accent)] transition-colors"
            placeholder="Au"
          />
          <button
            type="submit"
            className="px-3 py-1.5 text-xs rounded-lg bg-[var(--accent)] text-black font-semibold hover:brightness-110 transition-all"
          >
            Render
          </button>
        </form>
        <button
          onClick={handleRandom}
          className="p-1.5 rounded-lg border border-border hover:border-[var(--accent)] transition-colors"
          title="Random element"
        >
          <RefreshCw className="w-4 h-4 text-zinc-400" />
        </button>
      </div>

      {/* Visualization area */}
      <div className="flex-1 relative bg-grid flex items-center justify-center overflow-hidden">
        {error ? (
          <div className="text-center px-6">
            <Zap className="w-10 h-10 text-amber-500 mx-auto mb-3" />
            <p className="text-sm text-zinc-400">{error}</p>
          </div>
        ) : (
          <div className="relative flex items-center justify-center">
            {/* Nucleus */}
            <div
              className="absolute rounded-full flex items-center justify-center animate-pulse-glow z-10"
              style={{
                width: 40 + element.protons * 0.8,
                height: 40 + element.protons * 0.8,
                background: `radial-gradient(circle at 35% 35%, ${element.color}88, ${element.color}44, ${element.color}22)`,
                boxShadow: `0 0 30px ${element.color}44, 0 0 60px ${element.color}22`,
              }}
            >
              <span className="text-xs font-bold text-white font-mono drop-shadow-lg">
                {element.protons}p
              </span>
            </div>

            {/* Electron shells */}
            {element.shells.map((shell, i) => (
              <div
                key={i}
                className={`absolute rounded-full border ${ORBIT_STYLE[shell.direction]} opacity-40`}
                style={{
                  width: shell.radius * 2,
                  height: shell.radius * 2,
                  borderColor: `${element.color}66`,
                  borderStyle: "dashed",
                  borderWidth: 1,
                }}
              />
            ))}

            {/* Electrons as dots on orbits */}
            {element.shells.map((shell, shellIdx) =>
              Array.from({ length: shell.electrons }).map((_, eIdx) => {
                const angleOffset = (360 / shell.electrons) * eIdx;
                return (
                  <div
                    key={`${shellIdx}-${eIdx}`}
                    className="absolute"
                    style={{
                      width: shell.radius * 2,
                      height: shell.radius * 2,
                      animation: `${shell.direction === "normal" ? "orbit" : "orbit-reverse"} ${shell.speed}s linear infinite`,
                      animationDelay: `${-angleOffset * (shell.speed / 360)}s`,
                      transform: `rotate(${angleOffset}deg)`,
                    }}
                  >
                    <div
                      className="absolute rounded-full animate-pulse-glow"
                      style={{
                        width: 8,
                        height: 8,
                        background: `radial-gradient(circle at 40% 40%, ${element.color}, ${element.color}88)`,
                        boxShadow: `0 0 8px ${element.color}`,
                        top: -4,
                        left: shell.radius - 4,
                      }}
                    />
                  </div>
                );
              })
            )}
          </div>
        )}

        {/* Element info overlay */}
        {!error && (
          <div className="absolute bottom-4 left-4 bg-surface/90 backdrop-blur border border-border rounded-xl px-4 py-3">
            <div className="text-lg font-bold text-foreground font-mono">
              {formula.match(/^[A-Z][a-z]?/)?.[0] || formula}
            </div>
            <div className="text-xs text-zinc-400 mt-0.5">{element.name}</div>
            <div className="flex gap-4 mt-1 text-xs text-zinc-500 font-mono">
              <span>{element.protons} protons</span>
              <span>{element.neutrons} neutrons</span>
              <span>{element.shells.reduce((s, sh) => s + sh.electrons, 0)} electrons</span>
            </div>
          </div>
        )}

        {/* Instructions hint */}
        <p className="absolute bottom-4 right-4 text-xs text-zinc-600">
          Type a chemical symbol & press Enter
        </p>
      </div>
    </div>
  );
}
