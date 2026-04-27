export default function {page_name}() {
  return (
    <div className="space-y-4">
      <h1 className="text-3xl font-bold tracking-tight">{page_name}</h1>
      <p className="text-muted-foreground">
        {/* TODO: Replace this placeholder with real content */}
        This is the <strong>{page_name}</strong> page. Edit{' '}
        <code className="rounded bg-muted px-1 py-0.5 text-sm font-mono">
          src/pages/{page_name}.tsx
        </code>{' '}
        to get started.
      </p>
    </div>
  )
}
