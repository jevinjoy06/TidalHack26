import { MoreVertical } from "lucide-react";
import { Checkbox } from "./ui/checkbox";

interface TaskItemProps {
  title: string;
  subtitle?: string;
  dueTime?: string;
  priority?: "high" | "medium" | "low";
  completed?: boolean;
  onToggle?: () => void;
}

export function TaskItem({ title, subtitle, dueTime, priority, completed = false, onToggle }: TaskItemProps) {
  const priorityColors = {
    high: "bg-red-500/20 text-red-400 border-red-500/30",
    medium: "bg-yellow-500/20 text-yellow-400 border-yellow-500/30",
    low: "bg-blue-500/20 text-blue-400 border-blue-500/30",
  };

  return (
    <div className="group flex items-start gap-3 rounded-lg border border-border/50 bg-card/30 p-3 transition-all hover:border-accent/30 hover:bg-card/50">
      <Checkbox
        checked={completed}
        onCheckedChange={onToggle}
        className="mt-0.5"
      />
      
      <div className="flex-1">
        <p className={`text-sm ${completed ? "line-through text-muted-foreground" : "text-foreground"}`}>
          {title}
        </p>
        {subtitle && (
          <p className="text-xs text-muted-foreground mt-0.5">{subtitle}</p>
        )}
        <div className="mt-2 flex items-center gap-2">
          {dueTime && (
            <span className="text-xs text-muted-foreground">{dueTime}</span>
          )}
          {priority && (
            <span className={`rounded px-1.5 py-0.5 text-xs border ${priorityColors[priority]}`}>
              {priority}
            </span>
          )}
        </div>
      </div>
      
      <button
        className="opacity-0 group-hover:opacity-100 transition-opacity p-1 hover:bg-muted/50 rounded"
        aria-label="More options"
      >
        <MoreVertical className="h-4 w-4 text-muted-foreground" />
      </button>
    </div>
  );
}
