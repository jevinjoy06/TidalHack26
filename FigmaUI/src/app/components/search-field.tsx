import { Search } from "lucide-react";

interface SearchFieldProps {
  placeholder: string;
  value?: string;
  onChange?: (value: string) => void;
}

export function SearchField({ placeholder, value, onChange }: SearchFieldProps) {
  return (
    <div className="relative">
      <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
        className="w-full rounded-lg border border-border bg-input-background py-2 pl-9 pr-3 text-sm placeholder:text-muted-foreground focus:border-secondary/50 focus:outline-none focus:ring-2 focus:ring-secondary/30 transition-all"
      />
    </div>
  );
}