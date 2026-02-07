export function EmptyStateIllustration() {
  return (
    <div className="relative mx-auto mb-8 h-32 w-32">
      <svg
        viewBox="0 0 128 128"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="h-full w-full"
      >
        {/* Abstract geometric illustration */}
        <circle
          cx="64"
          cy="64"
          r="56"
          fill="#FEF2F2"
          className="opacity-60"
        />
        <circle
          cx="64"
          cy="64"
          r="40"
          fill="#FEE2E2"
          className="opacity-80"
        />
        <rect
          x="44"
          y="44"
          width="40"
          height="40"
          rx="8"
          fill="#DC2626"
          className="opacity-20"
        />
        <path
          d="M64 32L84 52L64 72L44 52L64 32Z"
          fill="#DC2626"
          className="opacity-40"
        />
        <circle
          cx="64"
          cy="64"
          r="12"
          fill="#DC2626"
        />
      </svg>
    </div>
  );
}
