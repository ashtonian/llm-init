---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/styles/**"
---

# UX Standards

Mandatory standards for user experience, accessibility, responsive design, and interaction patterns. Every user-facing feature must meet these standards.

## Accessibility (WCAG 2.1 AA)

Accessibility is not optional. Every feature must meet WCAG 2.1 AA compliance.

### Keyboard Navigation

| Requirement | Standard |
|-------------|----------|
| All interactive elements | Reachable via Tab key |
| Focus order | Follows visual/logical reading order |
| Focus indicator | Visible, minimum 2px outline, 3:1 contrast ratio |
| No keyboard traps | Can always Tab or Escape out of any component |
| Custom widgets | Implement ARIA keyboard patterns (arrow keys for menus, Enter/Space for buttons) |
| Skip navigation | "Skip to main content" link as first focusable element |

### Color and Contrast

| Requirement | Ratio |
|-------------|-------|
| Normal text (<18px) | 4.5:1 minimum |
| Large text (18px+ or 14px+ bold) | 3:1 minimum |
| UI components and graphics | 3:1 minimum |
| Focus indicator | 3:1 against adjacent colors |

**Never convey information by color alone.** Always supplement with icons, patterns, or text labels.

```tsx
// GOOD: Color + icon + text
<Badge variant="error">
  <AlertIcon /> Failed  {/* Color + icon + text */}
</Badge>

// BAD: Color only
<span style={{ color: 'red' }}>Failed</span>  {/* Color blind users miss this */}
```

### ARIA Requirements

```tsx
// Form fields: always have labels
<label htmlFor="email">Email address</label>
<input id="email" type="email" aria-required="true" aria-invalid={!!errors.email} />
{errors.email && <p id="email-error" role="alert">{errors.email}</p>}

// Dynamic content: announce updates
<div aria-live="polite" aria-atomic="true">
  {notification && <p>{notification}</p>}
</div>

// Modals: proper focus management
<dialog
  aria-modal="true"
  aria-labelledby="modal-title"
  onClose={handleClose}
>
  <h2 id="modal-title">Confirm Delete</h2>
  {/* Focus trapped inside modal, returns to trigger on close */}
</dialog>

// Icons: decorative vs informational
<SearchIcon aria-hidden="true" />  {/* Decorative: hide from screen readers */}
<button aria-label="Delete user">  {/* Informational: needs label */}
  <TrashIcon />
</button>
```

### Screen Reader Testing

Test that these announcements are correct:
- Page title changes on navigation
- Form error messages are announced
- Loading states are communicated
- Toast/notification content is read
- Table row counts and sorting state

## Responsive Breakpoints

| Breakpoint | Name | Layout |
|-----------|------|--------|
| 320px | Small mobile | Single column, stacked, hamburger nav |
| 768px | Tablet | Collapsible sidebar, 2-column possible |
| 1024px | Desktop | Full sidebar, multi-column, data tables |
| 1440px | Wide | Max content width (1280px), centered |

### Implementation

```css
/* Mobile-first: base styles for mobile */
.container {
  display: flex;
  flex-direction: column;
  padding: 16px;
}

/* Tablet and up */
@media (min-width: 768px) {
  .container {
    flex-direction: row;
    padding: 24px;
  }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .container {
    max-width: 1280px;
    margin: 0 auto;
    padding: 32px;
  }
}
```

### Mobile-Specific Requirements

| Requirement | Standard |
|-------------|----------|
| Font size | Minimum 16px (prevents iOS zoom on focus) |
| Touch targets | Minimum 44x44px |
| Touch target spacing | Minimum 8px gap between adjacent targets |
| Horizontal scroll | Never (except data tables with scroll indicator) |
| Text overflow | `overflow-wrap: break-word` for long strings |

## Touch Targets

```css
/* Minimum touch target */
.button, .link, .checkbox, .radio {
  min-height: 44px;
  min-width: 44px;
  padding: 12px 16px;
}

/* Spacing between adjacent targets */
.button + .button {
  margin-left: 8px;
}

/* Invisible touch expansion for small visual elements */
.small-icon-button {
  position: relative;
}
.small-icon-button::before {
  content: '';
  position: absolute;
  inset: -8px;  /* Expand touch area beyond visual bounds */
}
```

## Loading States

### Pattern Selection Guide

| Situation | Pattern | Duration |
|-----------|---------|----------|
| Initial page load | Skeleton screen | Until data arrives |
| Button action | Inline spinner + disabled | 0-3 seconds |
| Form submission | Button loading state + disabled form | 0-5 seconds |
| Long operation | Progress bar + description | 5+ seconds |
| Background refresh | No indicator (use staleTime) | N/A |
| Optimistic update | Immediate UI change, rollback on error | N/A |

### Skeleton Screen Pattern

```tsx
// Match the layout of the real content
function UserCardSkeleton() {
  return (
    <div className="card" aria-busy="true" aria-label="Loading user">
      <div className="skeleton skeleton-circle" style={{ width: 48, height: 48 }} />
      <div className="skeleton skeleton-text" style={{ width: '60%', height: 20 }} />
      <div className="skeleton skeleton-text" style={{ width: '40%', height: 16 }} />
    </div>
  );
}

// Skeleton animation
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}

@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### Optimistic Updates

```tsx
// Show the result immediately, rollback on error
function useToggleFavorite() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: api.favorites.toggle,
    onMutate: async (itemId) => {
      const previous = queryClient.getQueryData(['favorites']);
      queryClient.setQueryData(['favorites'], (old) =>
        old.includes(itemId)
          ? old.filter(id => id !== itemId)
          : [...old, itemId]
      );
      return { previous };
    },
    onError: (err, itemId, context) => {
      queryClient.setQueryData(['favorites'], context.previous);
      toast.error('Failed to update favorite');
    },
  });
}
```

## Error States

### Inline Validation

```tsx
// Validate on blur (not on every keystroke)
<input
  onBlur={() => trigger('email')}  // React Hook Form trigger
  aria-invalid={!!errors.email}
  aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && (
  <p id="email-error" role="alert" className="error-message">
    <AlertIcon aria-hidden="true" /> {errors.email.message}
  </p>
)}
```

### Form Error Summary

```tsx
// Show at the top of the form with links to each error
{Object.keys(errors).length > 0 && (
  <div role="alert" className="error-summary">
    <h3>Please fix the following errors:</h3>
    <ul>
      {Object.entries(errors).map(([field, error]) => (
        <li key={field}>
          <a href={`#${field}`}>{error.message}</a>
        </li>
      ))}
    </ul>
  </div>
)}
```

### Error Message Guidelines

| Situation | Bad Message | Good Message |
|-----------|------------|--------------|
| Required field | "Required" | "Name is required" |
| Invalid email | "Invalid" | "Enter a valid email address (e.g., name@example.com)" |
| API error | "Error 500" | "Something went wrong. Please try again." |
| Permission error | "403 Forbidden" | "You don't have permission to delete this user. Contact your admin." |
| Network error | "Network error" | "Unable to connect. Check your internet and try again." |
| Rate limited | "429" | "Too many requests. Please wait a moment and try again." |

## Empty States

Every list/collection view needs a meaningful empty state:

```tsx
function EmptyState({
  icon: Icon,
  title,
  description,
  action
}: EmptyStateProps) {
  return (
    <div className="empty-state">
      <Icon className="empty-state-icon" aria-hidden="true" />
      <h3>{title}</h3>
      <p>{description}</p>
      {action && (
        <Button onClick={action.onClick}>{action.label}</Button>
      )}
    </div>
  );
}

// Usage
<EmptyState
  icon={UsersIcon}
  title="No team members yet"
  description="Invite your team to start collaborating."
  action={{ label: "Invite Team Member", onClick: openInviteDialog }}
/>
```

## Micro-Interactions

| Type | Duration | Easing |
|------|----------|--------|
| Instant feedback (button press) | 100-200ms | ease-out |
| Transitions (expand/collapse) | 200-300ms | ease-in-out |
| Page transitions | 300-500ms | ease-in-out |
| Maximum animation duration | 500ms | N/A |

```css
/* Respect reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Standard transitions */
.expandable {
  transition: height 250ms ease-in-out, opacity 250ms ease-in-out;
}

.button {
  transition: background-color 150ms ease-out, transform 100ms ease-out;
}

.button:active {
  transform: scale(0.98);
}
```

## Navigation

### Breadcrumbs

```tsx
// Persistent breadcrumbs on every page
<nav aria-label="Breadcrumb">
  <ol className="breadcrumb">
    <li><Link to="/">Home</Link></li>
    <li><Link to="/users">Users</Link></li>
    <li aria-current="page">Jane Doe</li>
  </ol>
</nav>
```

Rules:
- Maximum 3 levels deep. If deeper, rethink the information architecture.
- Current page is not a link (uses `aria-current="page"`)
- Always show breadcrumbs on detail pages

### Navigation Structure

```
Primary nav (sidebar or top bar)
  ├── Dashboard
  ├── [Core Feature 1]
  ├── [Core Feature 2]
  ├── Team
  │   ├── Members
  │   ├── Invitations
  │   └── Roles
  └── Settings
      ├── Organization
      ├── Billing
      ├── API Keys
      └── Security
```

Rules:
- Maximum 7 (+/- 2) top-level items in primary navigation
- Group related items under a parent
- Current section highlighted in nav
- Mobile: hamburger menu or bottom tab bar (max 5 tabs)

## Data Tables

| Feature | Requirement |
|---------|-------------|
| Sorting | Click column header to sort, visual indicator for sort direction |
| Filtering | Filter controls above the table, active filters visible |
| Pagination | Below table, show current range ("Showing 1-50 of 1,234") |
| Row selection | Checkbox column, bulk action bar appears on selection |
| Column resize | Optional drag handles on column borders |
| Empty state | Full-width message with action CTA |
| Loading state | Skeleton rows matching table layout |
| Mobile | Card layout instead of table below 768px |

```tsx
// Responsive table pattern
function UserTable({ users }: { users: User[] }) {
  const isMobile = useMediaQuery('(max-width: 767px)');

  if (isMobile) {
    return <UserCardList users={users} />;  // Card layout for mobile
  }

  return (
    <table aria-label="Users">
      <thead>
        <tr>
          <th scope="col" aria-sort={sortState.name}>
            <SortableHeader field="name" />
          </th>
          {/* ... */}
        </tr>
      </thead>
      <tbody>
        {users.map(user => (
          <tr key={user.id}>
            <td>{user.name}</td>
            {/* ... */}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|----------------|
| Color-only status indicators | Color + icon + text |
| Placeholder-only labels | Visible labels above inputs |
| Auto-playing animations | Respect `prefers-reduced-motion` |
| Disabled buttons without explanation | Tooltip or helper text explaining why |
| Full-page spinners | Skeleton screens matching content layout |
| Generic error messages ("Error occurred") | Specific, actionable error messages |
| Blank empty states | Illustration + description + CTA |
| Custom scrollbars | Native scrollbars (accessibility) |
| Infinite scroll without keyboard access | Paginated or "Load More" button |
| Fixed pixel font sizes | Relative units (rem) for text |
