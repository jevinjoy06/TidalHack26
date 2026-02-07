import { ArrowRight } from "lucide-react";

interface PromptCardProps {
  text: string;
  onClick?: () => void;
}

export function PromptCard({ text, onClick }: PromptCardProps) {
  return (
    <button
      onClick={onClick}
      className="group relative flex items-start gap-3 rounded-xl border border-border bg-card/40 p-4 text-left backdrop-blur-sm transition-all hover:border-accent/50 hover:bg-card/60 hover:shadow-lg hover:shadow-accent/10 hover:-translate-y-0.5 focus:outline-none focus:ring-2 focus:ring-secondary/50"
    >
      <span className="flex-1 text-sm text-foreground">{text}</span>
      <ArrowRight className="mt-0.5 h-4 w-4 flex-shrink-0 text-muted-foreground transition-all group-hover:translate-x-0.5 group-hover:text-accent" />
      
      {/* Inner highlight */}
      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-accent/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
    </button>
  );
}