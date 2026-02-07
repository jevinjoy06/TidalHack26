import { ChevronRight, LucideIcon } from "lucide-react";
import { IconTile } from "./icon-tile";

interface SettingsRowProps {
  icon: LucideIcon;
  label: string;
  value?: string;
  onClick?: () => void;
  rightElement?: React.ReactNode;
}

export function SettingsRow({ icon, label, value, onClick, rightElement }: SettingsRowProps) {
  return (
    <button
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-lg border border-border/50 bg-card/30 p-4 text-left transition-all hover:border-accent/30 hover:bg-card/50 focus:outline-none focus:ring-2 focus:ring-secondary/50"
    >
      <IconTile icon={icon} size="sm" />
      
      <div className="flex-1">
        <p className="text-sm text-foreground">{label}</p>
        {value && (
          <p className="text-xs text-muted-foreground mt-0.5">{value}</p>
        )}
      </div>
      
      {rightElement || <ChevronRight className="h-4 w-4 text-muted-foreground" />}
    </button>
  );
}
