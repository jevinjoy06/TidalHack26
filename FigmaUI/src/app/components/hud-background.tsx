export function HudBackground() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden opacity-30">
      <svg
        className="absolute left-1/2 top-1/2 h-[800px] w-[800px] -translate-x-1/2 -translate-y-1/2"
        viewBox="0 0 800 800"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Concentric circles */}
        <circle cx="400" cy="400" r="350" stroke="#dc2626" strokeWidth="0.5" opacity="0.3" />
        <circle cx="400" cy="400" r="280" stroke="#dc2626" strokeWidth="0.5" opacity="0.4" />
        <circle cx="400" cy="400" r="210" stroke="#0ea5e9" strokeWidth="0.5" opacity="0.5" />
        <circle cx="400" cy="400" r="140" stroke="#0ea5e9" strokeWidth="0.5" opacity="0.6" />
        
        {/* Grid lines */}
        <line x1="400" y1="50" x2="400" y2="750" stroke="#dc2626" strokeWidth="0.3" opacity="0.2" />
        <line x1="50" y1="400" x2="750" y2="400" stroke="#dc2626" strokeWidth="0.3" opacity="0.2" />
        
        {/* Diagonal crosshairs */}
        <line x1="200" y1="200" x2="600" y2="600" stroke="#0ea5e9" strokeWidth="0.3" opacity="0.2" />
        <line x1="600" y1="200" x2="200" y2="600" stroke="#0ea5e9" strokeWidth="0.3" opacity="0.2" />
        
        {/* Scanning arc */}
        <path
          d="M 400 50 A 350 350 0 0 1 650 250"
          stroke="#dc2626"
          strokeWidth="1.5"
          fill="none"
          opacity="0.6"
          strokeLinecap="round"
        />
        
        {/* Data points */}
        <circle cx="300" cy="200" r="2" fill="#0ea5e9" opacity="0.8" />
        <circle cx="500" cy="250" r="2" fill="#dc2626" opacity="0.8" />
        <circle cx="350" cy="550" r="2" fill="#0ea5e9" opacity="0.8" />
        <circle cx="550" cy="500" r="2" fill="#dc2626" opacity="0.8" />
        
        {/* Corner brackets */}
        <path d="M 100 100 L 100 150 M 100 100 L 150 100" stroke="#0ea5e9" strokeWidth="1" opacity="0.4" />
        <path d="M 700 100 L 700 150 M 700 100 L 650 100" stroke="#0ea5e9" strokeWidth="1" opacity="0.4" />
        <path d="M 100 700 L 100 650 M 100 700 L 150 700" stroke="#0ea5e9" strokeWidth="1" opacity="0.4" />
        <path d="M 700 700 L 700 650 M 700 700 L 650 700" stroke="#0ea5e9" strokeWidth="1" opacity="0.4" />
      </svg>
    </div>
  );
}
