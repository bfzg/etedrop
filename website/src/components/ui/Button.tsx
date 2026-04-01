import React, {forwardRef} from 'react';
import Link, {type Props as DocusaurusLinkProps} from '@docusaurus/Link';
import clsx from 'clsx';

type Variant = 'primary' | 'default' | 'text';
type Size = 'md' | 'lg';

type CommonProps = {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  icon?: React.ReactNode;
  iconPosition?: 'left' | 'right';
  className?: string;
};

function Spinner({className}: {className?: string}) {
  return (
    <span
      className={clsx(
        'inline-block h-4 w-4 animate-spin rounded-full border-2 border-current border-b-transparent',
        className,
      )}
      aria-hidden="true"
    />
  );
}

function getClasses({variant, size}: {variant: Variant; size: Size}) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded-full no-underline transition ' +
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/30 focus-visible:ring-offset-2 focus-visible:ring-offset-white ' +
    'disabled:pointer-events-none disabled:opacity-60';

  const sizes: Record<Size, string> = {
    md: 'px-10 py-2.5 text-sm font-semibold',
    lg: 'px-10 py-3 text-base font-semibold',
  };

  const variants: Record<Variant, string> = {
    primary: 'bg-primary text-white hover:bg-primaryHover',
    default: 'bg-transparent text-black border border-solid border-gray-300 hover:bg-gray-200',
    text: 'bg-transparent text-primary hover:bg-gray-200',
  };

  return clsx(base, sizes[size], variants[variant]);
}

function ButtonInnerContent({
  loading,
  icon,
  iconPosition,
  children,
}: Pick<CommonProps, 'loading' | 'icon' | 'iconPosition'> & {children: React.ReactNode}) {
  const resolvedIcon = loading ? <Spinner /> : icon ? <span className="inline-flex">{icon}</span> : null;

  if (iconPosition === 'right') {
    return (
      <>
        <span className={loading ? 'opacity-80' : undefined}>{children}</span>
        {resolvedIcon}
      </>
    );
  }

  return (
    <>
      {resolvedIcon}
      <span className={loading ? 'opacity-80' : undefined}>{children}</span>
    </>
  );
}

export type ButtonProps = Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'color'> &
  CommonProps & {
    variant?: Variant;
  };

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'default',
    size = 'md',
    loading = false,
    icon,
    iconPosition = 'left',
    className,
    disabled,
    children,
    type = 'button',
    ...rest
  },
  ref,
) {
  const isDisabled = disabled || loading;

  return (
    <button
      ref={ref}
      type={type}
      className={clsx(getClasses({variant, size}), className)}
      disabled={isDisabled}
      aria-busy={loading || undefined}
      {...rest}
    >
      <ButtonInnerContent loading={loading} icon={icon} iconPosition={iconPosition}>
        {children}
      </ButtonInnerContent>
    </button>
  );
});

export type ButtonLinkProps = Omit<DocusaurusLinkProps, 'className'> &
  CommonProps & {
    variant?: Variant;
  };

export const ButtonLink = forwardRef<HTMLAnchorElement, ButtonLinkProps>(function ButtonLink(
  {
    variant = 'default',
    size = 'md',
    loading = false,
    icon,
    iconPosition = 'left',
    className,
    children,
    onClick,
    ...rest
  },
  ref,
) {
  const isDisabled = loading;

  return (
    <Link
      {...rest}
      ref={ref}
      className={clsx(getClasses({variant, size}), isDisabled && 'pointer-events-none opacity-60', className)}
      aria-busy={loading || undefined}
      aria-disabled={isDisabled || undefined}
      onClick={(e) => {
        if (isDisabled) {
          e.preventDefault();
          return;
        }
        onClick?.(e);
      }}
    >
      <ButtonInnerContent loading={loading} icon={icon} iconPosition={iconPosition}>
        {children}
      </ButtonInnerContent>
    </Link>
  );
});

