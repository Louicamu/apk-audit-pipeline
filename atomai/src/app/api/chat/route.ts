import { NextRequest, NextResponse } from "next/server";

// ── Knowledge base for the materials physics professor ──

const ELEMENT_DB: Record<string, { name: string; z: number; summary: string }> = {
  H:  { name: "Hydrogen",   z: 1,  summary: "the simplest element — one proton, one electron. Forms the majority of baryonic matter in the universe. Its single 1s orbital makes it the foundation of quantum mechanical models." },
  He: { name: "Helium",     z: 2,  summary: "a noble gas with a filled 1s² shell — chemically inert and the second most abundant element in the universe. Its closed-shell configuration makes it a textbook example of atomic stability." },
  Li: { name: "Lithium",    z: 3,  summary: "the lightest alkali metal, with [He]2s¹ configuration. Critical in battery technology due to its high electrochemical potential and low density. Its single valence electron creates a body-centered cubic (BCC) crystal structure." },
  C:  { name: "Carbon",     z: 6,  summary: "the backbone of organic chemistry with [He]2s²2p² configuration. Its ability to form sp, sp², and sp³ hybrid orbitals enables diamond (sp³), graphite/graphene (sp²), and nanotubes — making it the most versatile element in materials science." },
  O:  { name: "Oxygen",     z: 8,  summary: "the third most abundant element, with [He]2s²2p⁴ configuration. Its high electronegativity (3.44 Pauling) drives oxidation reactions and makes it central to oxide ceramics, superconductors, and corrosion science." },
  Na: { name: "Sodium",     z: 11, summary: "an alkali metal with [Ne]3s¹ — highly reactive, soft, and silvery. In materials science, sodium is used in Na-ion batteries as a cheaper alternative to lithium, and its vapor lamps demonstrate characteristic D-line emission." },
  Si: { name: "Silicon",    z: 14, summary: "the semiconductor that powers modern civilization. [Ne]3s²3p². Its diamond-cubic crystal structure and 1.12 eV indirect band gap make it the foundation of transistors, solar cells, and MEMS devices. Doping with B (p-type) or P (n-type) creates the p-n junction." },
  Fe: { name: "Iron",       z: 26, summary: "the most stable nucleus (binding energy per nucleon). [Ar]3d⁶4s². Its BCC (α-Fe) to FCC (γ-Fe) phase transition at 912°C is a classic example of allotropy. Ferromagnetic below its Curie temperature (770°C), it underpins steel metallurgy." },
  Cu: { name: "Copper",     z: 29, summary: "a noble metal with [Ar]3d¹⁰4s¹ — exceptional electrical conductivity (5.96×10⁷ S/m). Its FCC structure and ductility make it ideal for wiring. Also the basis of high-temperature superconductors (cuprates like YBCO)." },
  Au: { name: "Gold",       z: 79, summary: "a noble metal with [Xe]4f¹⁴5d¹⁰6s¹. Relativistic effects contract the 6s orbital, giving gold its characteristic yellow color and resistance to oxidation. Used in nanotechnology (Au nanoparticles exhibit plasmon resonance) and as an ideal inert electrode." },
};

const TOPIC_KB: Record<string, string> = {
  "band structure": "**Band Structure**\n\nIn a crystal, the periodic potential splits atomic energy levels into *bands* separated by *gaps*.\n\n- **Valence Band** — highest occupied band at T=0K\n- **Conduction Band** — lowest unoccupied band\n- **Band Gap (Eg)** — the energy range with no allowed states\n\nMaterials are classified by Eg:\n- **Metals**: overlapping bands or partially filled (Eg ≈ 0)\n- **Semiconductors**: small gap (0.1–3 eV, e.g., Si = 1.12 eV)\n- **Insulators**: large gap (Eg > 5 eV, e.g., diamond = 5.5 eV)\n\nThe band structure is calculated by solving the Schrödinger equation in a periodic potential (Bloch's theorem): ψ_k(r) = u_k(r)·e^(ik·r)",
  "defect": "**Crystal Lattice Defects**\n\nReal crystals are never perfect — defects determine many material properties:\n\n**Point Defects (0D):**\n- **Vacancy**: missing atom (Schottky defect in ionic crystals)\n- **Interstitial**: extra atom squeezed between lattice sites\n- **Frenkel Defect**: atom moves from lattice site to interstitial\n- **Substitutional**: foreign atom replaces host atom (doping!)\n\n**Line Defects (1D):**\n- **Edge Dislocation**: extra half-plane of atoms\n- **Screw Dislocation**: helical ramp around dislocation line\n\n**Why defects matter:** They control mechanical strength (dislocation motion = plasticity), electrical conductivity (dopants in Si), color (F-centers in NaCl → blue), and diffusion rates.",
  "graphene": "**Graphene — A 2D Wonder Material**\n\nGraphene is a single atomic layer of carbon atoms arranged in a hexagonal honeycomb lattice (sp² hybridization).\n\n**Key Properties:**\n- **Electronic**: Linear dispersion near the Dirac points → massless Dirac fermions. Electron mobility exceeds 200,000 cm²/V·s.\n- **Mechanical**: Young's modulus ≈ 1 TPa — stronger than steel at 1/1000 the weight.\n- **Thermal**: Conductivity ~5000 W/m·K, surpassing diamond.\n- **Optical**: Absorbs exactly πα ≈ 2.3% of white light per layer.\n\n**Applications**: flexible electronics, composite materials, desalination membranes, biosensors, and as a model system for relativistic quantum mechanics in a tabletop experiment.",
  "doping": "**Semiconductor Doping**\n\nDoping is the intentional introduction of impurities to control electrical properties:\n\n**n-type (electron donors):**\n- Add Group V elements (P, As) to Si\n- Extra valence electron → donor level just below conduction band\n- Electrons become majority carriers\n\n**p-type (hole donors/acceptors):**\n- Add Group III elements (B, Al) to Si\n- Missing electron → acceptor level just above valence band\n- Holes become majority carriers\n\n**The p-n junction** — bringing n-type and p-type together — creates a depletion region and built-in electric field. This is the basis of diodes, transistors, solar cells, and LEDs. The Shockley diode equation describes the I-V characteristic: I = I_s(e^(V/nV_T) - 1).",
  "perovskite": "**Perovskite Materials**\n\nPerovskites have the general formula ABX₃ (e.g., CaTiO₃) with a cubic crystal structure:\n\n- **A-site**: large cation (organic MA⁺/FA⁺ or inorganic Cs⁺)\n- **B-site**: smaller metal cation (Pb²⁺, Sn²⁺)\n- **X-site**: anion (O²⁻, I⁻, Br⁻, Cl⁻)\n\n**Why they're exciting:**\n- **Solar cells**: Power conversion efficiency jumped from 3.8% (2009) to >26% (2024) — the fastest improvement in photovoltaic history.\n- **Tolerance factor** (Goldschmidt): t = (r_A + r_X) / [√2(r_B + r_X)] — predicts stable perovskite formation when 0.8 < t < 1.0.\n- **Multiferroics**: Some oxide perovskites show coexisting ferroelectric and magnetic order.\n\n**Challenge**: Stability under humidity, heat, and UV remains the main barrier to commercialization.",
  "superconductor": "**Superconductivity**\n\nThe complete loss of electrical resistance below a critical temperature (Tc):\n\n- **BCS Theory** (Bardeen-Cooper-Schrieffer): electrons form Cooper pairs via phonon-mediated attraction, condensing into a single quantum ground state.\n- **Meissner Effect**: perfect diamagnetism — superconductors expel magnetic fields.\n- **Type I vs Type II**: Type II allows partial flux penetration (vortices) in the mixed state.\n\n**Key materials:**\n- NbTi (Tc = 9.2 K) — MRI machines\n- YBCO (Tc = 93 K) — first above liquid N₂ boiling point\n- H₃S under pressure (Tc ≈ 203 K) — record for conventional superconductors\n- Cuprates and nickelates — still not fully explained by BCS.\n\nRoom-temperature superconductivity remains the holy grail of condensed matter physics.",
  "quantum dot": "**Quantum Dots**\n\nSemiconductor nanocrystals (2-10 nm) where excitons are confined in all three spatial dimensions — essentially 'artificial atoms.'\n\n**Key physics:**\n- **Quantum confinement**: as size decreases, the band gap increases → tunable emission color (CdSe: blue at 2 nm, red at 8 nm).\n- **Discrete energy levels**: unlike bulk semiconductors, density of states becomes delta-function-like.\n- **Brus equation**: E_g(QD) = E_g(bulk) + (ħ²π²/2μR²) — 1.8e²/εR ... predicts size-dependent band gap.\n\n**Applications**: QLED displays (Samsung QD-OLED), bio-imaging labels, single-photon sources for quantum cryptography, and intermediate-band solar cells.",
};

function detectTopic(message: string): string | null {
  const lower = message.toLowerCase();
  if (lower.includes("band") && (lower.includes("structure") || lower.includes("gap") || lower.includes("theory"))) return "band structure";
  if (lower.includes("defect") || lower.includes("frenkel") || lower.includes("schottky") || lower.includes("vacancy") || lower.includes("dislocation")) return "defect";
  if (lower.includes("graphene") || lower.includes("2d material") || lower.includes("nanotube")) return "graphene";
  if (lower.includes("dop") || lower.includes("p-n") || lower.includes("pn junction") || lower.includes("n-type") || lower.includes("p-type")) return "doping";
  if (lower.includes("perovskite")) return "perovskite";
  if (lower.includes("superconduct") || lower.includes("bcs") || lower.includes("meissner") || lower.includes("cooper pair")) return "superconductor";
  if (lower.includes("quantum dot") || lower.includes("nanocrystal") || lower.includes("qd")) return "quantum dot";
  return null;
}

function generateResponse(message: string): string {
  const lower = message.toLowerCase().trim();

  // Check for chemical element symbol (standalone)
  const elementMatch = message.trim().match(/^(H|He|Li|Be|B|C|N|O|F|Ne|Na|Mg|Al|Si|P|S|Cl|Ar|K|Ca|Fe|Cu|Zn|Ag|Au|Pt|Pb|U)$/i);
  if (elementMatch) {
    const symbol = elementMatch[1].charAt(0).toUpperCase() + elementMatch[1].slice(1).toLowerCase();
    const el = ELEMENT_DB[symbol];
    if (el) {
      return `**${el.name} (${symbol}, Z=${el.z})**\n\n${el.summary}\n\nWhat specific aspect of ${el.name} would you like to explore further? I can discuss its electronic configuration, crystal structure, common compounds, or role in materials applications.`;
    }
  }

  // Check for "summarize" / "explain" + element
  const explainMatch = lower.match(/(?:summarize|explain|tell me about|what is|describe)\s+([A-Z][a-z]?)/i);
  if (explainMatch) {
    const symbol = explainMatch[1].charAt(0).toUpperCase() + explainMatch[1].slice(1).toLowerCase();
    const el = ELEMENT_DB[symbol];
    if (el) {
      return `**${el.name} (${symbol}, Z=${el.z})**\n\n${el.summary}\n\nWould you like to dive deeper into ${el.name}'s crystal structure, electronic properties, or its role in specific applications?`;
    }
  }

  // Check for known topics
  const topicKey = detectTopic(message);
  if (topicKey && TOPIC_KB[topicKey]) {
    return TOPIC_KB[topicKey];
  }

  // General material science questions
  if (lower.includes("crystal") && (lower.includes("structure") || lower.includes("lattice"))) {
    return "**Crystal Structures — The 7 Systems**\n\nCrystalline materials organize atoms into periodic arrangements. The 7 crystal systems are:\n\n- **Cubic** (a=b=c, α=β=γ=90°) — most symmetric; includes SC, BCC, FCC\n- **Tetragonal** (a=b≠c, α=β=γ=90°)\n- **Orthorhombic** (a≠b≠c, α=β=γ=90°)\n- **Hexagonal** (a=b≠c, α=β=90°, γ=120°)\n- **Rhombohedral** (a=b=c, α=β=γ≠90°)\n- **Monoclinic** (a≠b≠c, α=γ=90°, β≠90°)\n- **Triclinic** (a≠b≠c, α≠β≠γ≠90°) — least symmetric\n\nCombined with centering (primitive, body, face, base) = 14 Bravais lattices. The most common metallic structures are BCC (Fe, W), FCC (Al, Cu, Au), and HCP (Ti, Zn).";
  }

  if (lower.includes("phase") && (lower.includes("diagram") || lower.includes("transition"))) {
    return "**Phase Diagrams & Transitions**\n\nA phase diagram maps the stable phases of a material as a function of temperature, pressure, and composition.\n\n**Gibbs Phase Rule**: F = C - P + 2\n(F = degrees of freedom, C = components, P = phases)\n\n**Key transitions:**\n- **First-order**: discontinuous change in entropy/volume (melting, boiling) — involves latent heat\n- **Second-order**: continuous entropy, discontinuous heat capacity (ferromagnetic transition at Curie point, superconducting transition)\n\n**Lever Rule** — in a two-phase region, the fraction of each phase is inversely proportional to the distance from the phase boundaries.\n\nThe Fe-C phase diagram (steel) is arguably the most economically important phase diagram in human civilization.";
  }

  if (lower.includes("hello") || lower.includes("hi") || lower.includes("hey")) {
    return "Welcome! I'm Professor Aris Tensor. I specialize in explaining materials physics — from atomic orbitals to phase diagrams. Feel free to ask me about:\n\n- **Chemical elements** (type a symbol like 'Au' or 'Fe')\n- **Band theory** and electronic properties\n- **Crystal defects** and mechanical behavior\n- **Graphene**, perovskites, superconductors, quantum dots\n- **Semiconductor physics** and doping\n\nWhat would you like to learn about today?";
  }

  if (lower.includes("thank")) {
    return "You're most welcome! Science is a collaborative endeavor — I'm glad I could help illuminate these concepts. Remember, as Richard Feynman said, 'The pleasure of finding things out' is what drives us. Come back anytime you have more questions about the fascinating world of materials!";
  }

  // Fallback
  return `**An interesting question!**\n\nAs a materials physicist, I'd approach this by considering the underlying principles:\n\n- The electronic structure determines bonding, optical, and transport properties\n- The crystal lattice and its defects govern mechanical and thermal behavior\n- Processing history creates microstructure, which bridges atomic-scale physics to macroscopic properties\n\nCould you be a bit more specific? I'm here to help with:\n- Atomic/electronic structure of specific elements\n- Band theory and semiconductor physics\n- Crystal defects and mechanical properties\n- Advanced materials (graphene, perovskites, superconductors)\n- Phase diagrams and thermodynamics`;
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const message = (body.message || "").trim();

    if (!message) {
      return NextResponse.json(
        { error: "Message is required" },
        { status: 400 }
      );
    }

    if (message.length > 2000) {
      return NextResponse.json(
        { error: "Message too long — please keep it under 2000 characters" },
        { status: 400 }
      );
    }

    // Simulate a small delay to feel like AI processing
    await new Promise((resolve) => setTimeout(resolve, 500 + Math.random() * 1000));

    const reply = generateResponse(message);

    return NextResponse.json({ reply }, { status: 200 });
  } catch {
    return NextResponse.json(
      { error: "Failed to process request" },
      { status: 500 }
    );
  }
}
