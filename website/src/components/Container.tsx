import type { ReactNode } from "react";
import clsx from "clsx";

export default function Container({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={clsx(
        "mx-auto w-full max-w-[1180px] px-2 lg:px-0 py-6 lg:py-24",
        className,
      )}
    >
      {children}
    </div>
  );
}
