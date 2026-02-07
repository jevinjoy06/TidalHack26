import { RefreshCw, LucideIcon } from "lucide-react";
import { IconTile } from "./icon-tile";

interface StatusCardProps {
  icon: LucideIcon;
  status: "connected" | "degraded" | "disconnected";
  title: string;
  subtitle?: string;
  lastChecked?: string;
  onRefresh?: () => void;
}

export function StatusCard({ icon, status, title, subtitle, lastChecked, onRefresh }: StatusCardProps) {
  const statusVariant = {
    connected: "success" as const,
    degraded: "warning" as const,
    disconnected: "error" as const,
  };

  const statusText = {
    connected: "Connected",
    degraded: "Degraded",
    disconnected: "Disconnected",
  };

  return (
    <div className="relative overflow-hidden rounded-xl border border-border bg-card/40 p-6 backdrop-blur-sm">
      {/* Subtle HUD rings background */}
      <div className="pointer-events-none absolute right-0 top-0 h-32 w-32 opacity-10">
        <svg viewBox="0 0 100 100" fill="none">
          <circle cx="50" cy="50" r="40" stroke="currentColor" strokeWidth="0.5" className="text-accent" />
          <circle cx="50" cy="50" r="30" stroke="currentColor" strokeWidth="0.5" className="text-secondary" />
          <circle cx="50" cy="50" r="20" stroke="currentColor" strokeWidth="0.5" className="text-accent" />
        </svg>
      </div>

      <div className="relative flex items-start gap-4">
        <IconTile icon={icon} variant={statusVariant[status]} size="lg" />
        
        <div className="flex-1">
          <h3 className="text-lg text-foreground">{statusText[status]}</h3>
          <p className="text-sm text-muted-foreground mt-1">{subtitle || "API is ready"}</p>
          {lastChecked && (
            <p className="text-xs text-muted-foreground/70 mt-2">Last checked: {lastChecked}</p>
          )}
        </div>
        
        {onRefresh && (
          <button
            onClick={onRefresh}
            className="rounded-lg p-2 transition-all hover:bg-muted/50 focus:outline-none focus:ring-2 focus:ring-secondary/50"
            aria-label="Refresh status"
          >
            <RefreshCw className="h-4 w-4 text-muted-foreground" />
          </button>
        )}
      </div>
    </div>
  );
}
