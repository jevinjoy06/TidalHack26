import { LucideIcon } from "lucide-react";

interface IconTileProps {
  icon: LucideIcon;
  variant?: "default" | "success" | "warning" | "error";
  size?: "sm" | "md" | "lg";
}

export function IconTile({ icon: Icon, variant = "default", size = "md" }: IconTileProps) {
  const sizeClasses = {
    sm: "h-8 w-8",
    md: "h-10 w-10",
    lg: "h-12 w-12",
  };

  const variantClasses = {
    default: "bg-accent/20 text-accent border-accent/30",
    success: "bg-green-500/20 text-green-400 border-green-500/30",
    warning: "bg-yellow-500/20 text-yellow-400 border-yellow-500/30",
    error: "bg-red-500/20 text-red-400 border-red-500/30",
  };

  const iconSizes = {
    sm: "h-3.5 w-3.5",
    md: "h-4 w-4",
    lg: "h-5 w-5",
  };

  return (
    <div
      className={`flex items-center justify-center rounded-lg border ${sizeClasses[size]} ${variantClasses[variant]}`}
    >
      <Icon className={iconSizes[size]} />
    </div>
  );
}
