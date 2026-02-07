import { Send, Mic } from "lucide-react";

interface ChatInputBarProps {
  placeholder?: string;
  onSend?: (message: string) => void;
}

export function ChatInputBar({ placeholder = "Ask JARVIS anything…", onSend }: ChatInputBarProps) {
  return (
    <div className="relative mx-auto w-full max-w-4xl">
      <div className="relative flex items-center gap-2 rounded-2xl border border-border bg-card/60 p-2 backdrop-blur-sm shadow-lg shadow-accent/5">
        <input
          type="text"
          placeholder={placeholder}
          className="flex-1 bg-transparent px-4 py-3 text-sm placeholder:text-muted-foreground focus:outline-none"
          onKeyDown={(e) => {
            if (e.key === "Enter" && e.currentTarget.value.trim()) {
              onSend?.(e.currentTarget.value);
              e.currentTarget.value = "";
            }
          }}
        />
        
        <button
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-muted/50 text-muted-foreground transition-all hover:bg-muted hover:text-foreground focus:outline-none focus:ring-2 focus:ring-secondary/50"
          aria-label="Voice input"
        >
          <Mic className="h-4 w-4" />
        </button>
        
        <button
          onClick={() => {
            const input = document.querySelector('input[placeholder*="JARVIS"]') as HTMLInputElement;
            if (input?.value.trim()) {
              onSend?.(input.value);
              input.value = "";
            }
          }}
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent text-accent-foreground transition-all hover:bg-accent/90 focus:outline-none focus:ring-2 focus:ring-secondary/50 shadow-sm shadow-accent/30"
          aria-label="Send message"
        >
          <Send className="h-4 w-4" />
        </button>
      </div>
      
      {/* Bottom glow effect */}
      <div className="pointer-events-none absolute -bottom-1 left-1/2 h-8 w-3/4 -translate-x-1/2 bg-accent/10 blur-xl" />
    </div>
  );
}
