import { MessageSquare } from "lucide-react";

interface ChatItemProps {
  title: string;
  timestamp: string;
  active?: boolean;
  onClick?: () => void;
}

export function ChatItem({ title, timestamp, active = false, onClick }: ChatItemProps) {
  return (
    <button
      onClick={onClick}
      className={`group flex w-full items-start gap-3 rounded-lg px-3 py-2.5 text-left transition-all focus:outline-none focus:ring-2 focus:ring-secondary/50 ${
        active
          ? "bg-accent/10 border border-accent/30"
          : "hover:bg-sidebar-accent hover:border hover:border-border/50"
      }`}
    >
      <MessageSquare className={`h-4 w-4 mt-0.5 flex-shrink-0 ${active ? "text-accent" : "text-muted-foreground"}`} />
      <div className="flex-1 overflow-hidden">
        <p className={`text-sm truncate ${active ? "text-accent" : "text-foreground"}`}>{title}</p>
        <p className="text-xs text-muted-foreground">{timestamp}</p>
      </div>
    </button>
  );
}
