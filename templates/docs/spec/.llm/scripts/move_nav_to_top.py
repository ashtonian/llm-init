#!/usr/bin/env python3
"""
Move LLM Navigation Guide sections from the end to the top of spec files.

This script:
1. Finds the LLM Navigation Guide section in a file
2. Extracts it (including subsections up to "Related Documentation" or end)
3. Removes it from its current position
4. Inserts it after the first title/intro paragraph
5. Adds a one-line summary blockquote
"""

import os
import re
import sys
from pathlib import Path


def extract_llm_section(content: str) -> tuple[str, str, int, int]:
    """
    Extract the LLM Navigation Guide section from content.
    Returns: (section_content, remaining_content, start_idx, end_idx)
    """
    # Find the start of LLM Navigation Guide section
    pattern = r'\n---\n+## LLM Navigation Guide\n'
    match = re.search(pattern, content)
    if not match:
        # Try without leading separator
        pattern = r'\n## LLM Navigation Guide\n'
        match = re.search(pattern, content)
        if not match:
            return None, content, -1, -1

    start_idx = match.start()

    # Find the end - either "## Related Documentation" or end of file
    end_patterns = [
        r'\n---\n+## Related Documentation',
        r'\n## Related Documentation',
        r'\n---\n+## Changelog',
        r'\n## Changelog',
    ]

    end_idx = len(content)
    for ep in end_patterns:
        m = re.search(ep, content[start_idx:])
        if m:
            candidate = start_idx + m.start()
            if candidate < end_idx:
                end_idx = candidate

    # If we found Related Documentation, include it
    if end_idx < len(content):
        # Find the next major section after Related Documentation
        after_related = content[end_idx:]
        next_section = re.search(r'\n## [^R]', after_related)
        if next_section:
            end_idx = end_idx + next_section.start()
        else:
            end_idx = len(content)

    section = content[start_idx:end_idx].strip()
    remaining = content[:start_idx].rstrip() + '\n\n' + content[end_idx:].lstrip()

    return section, remaining, start_idx, end_idx


def get_title_and_intro(content: str) -> tuple[str, int]:
    """
    Find the title (# line) and any intro paragraph.
    Returns: (title_section, end_position)
    """
    lines = content.split('\n')
    title_end = 0

    for i, line in enumerate(lines):
        if line.startswith('# '):
            title_end = i + 1
            # Skip any immediately following blank lines and intro paragraph
            while title_end < len(lines):
                if lines[title_end].strip() == '':
                    title_end += 1
                elif lines[title_end].startswith('#'):
                    break
                elif lines[title_end].startswith('---'):
                    break
                elif lines[title_end].startswith('>'):
                    # Already has a blockquote, skip it
                    title_end += 1
                    while title_end < len(lines) and lines[title_end].strip() != '':
                        title_end += 1
                    break
                else:
                    # Include intro paragraph
                    while title_end < len(lines) and lines[title_end].strip() != '':
                        title_end += 1
                    break
            break

    return '\n'.join(lines[:title_end]), title_end


def create_summary_from_title(title: str) -> str:
    """Create a one-line summary from the document title."""
    # Remove the # prefix
    title_text = title.strip().lstrip('#').strip()

    # Generic summaries based on common title patterns
    summaries = {
        'api-design': 'REST conventions, model patterns, pagination, and content negotiation.',
        'authentication': 'JWT, API keys, OIDC, mTLS, and session management.',
        'data-access': 'Repository patterns, database integration, and query operations.',
        'error-handling': 'Error codes, HTTP status mapping, and retry behavior.',
        'models': 'Entity patterns, soft delete, audit trails, and versioning.',
        'routes': 'Route structure, middleware, and endpoint patterns.',
        'observability': 'Structured logging, tracing, and metrics.',
        'permission': 'Policy enforcement, access control, and field-level permissions.',
        'tenant': 'Multi-tenant hierarchy, isolation, and domain routing.',
        'caching': 'Two-tier caching (L1/L2), invalidation, and rate limiting.',
        'time-series': 'Time-series storage with pluggable backends.',
        'blobs': 'Binary object storage with pluggable backends.',
        'webhooks': 'Outbound webhook delivery with retries and signing.',
        'rule-engine': 'Multi-expression language rules and evaluation.',
        'workflow': 'Multi-step workflows, actions, and compensation.',
        'pipeline': 'Data processing pipeline stages.',
    }

    # Try to match based on filename pattern
    for key, summary in summaries.items():
        if key.lower() in title_text.lower():
            return summary

    # Default summary
    return f'{title_text} specification and patterns.'


def process_file(filepath: str, dry_run: bool = False) -> bool:
    """
    Process a single file to move LLM Navigation section to top.
    Returns True if file was modified.
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip if already has LLM section near the top (within first 100 lines)
    first_lines = '\n'.join(content.split('\n')[:100])
    if '## LLM Navigation Guide' in first_lines:
        print(f'SKIP (already at top): {filepath}')
        return False

    # Extract LLM section
    section, remaining, start, end = extract_llm_section(content)
    if section is None:
        print(f'SKIP (no LLM section): {filepath}')
        return False

    # Clean up the section - remove leading ---
    section = section.lstrip('-').strip()
    if not section.startswith('## LLM'):
        section = '## LLM Navigation Guide\n' + section

    # Get title position
    title_section, title_end_line = get_title_and_intro(remaining)

    # Check if there's already a blockquote summary
    lines = remaining.split('\n')
    has_blockquote = False
    for i, line in enumerate(lines):
        if line.startswith('# '):
            # Look for blockquote in next few lines
            for j in range(i+1, min(i+5, len(lines))):
                if lines[j].startswith('> '):
                    has_blockquote = True
                    break
                if lines[j].startswith('#'):
                    break
            break

    # Build new content
    title_line_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('# '):
            title_line_idx = i
            break

    # Find where to insert (after title and any existing blockquote/intro)
    insert_idx = title_line_idx + 1
    while insert_idx < len(lines):
        line = lines[insert_idx]
        if line.strip() == '':
            insert_idx += 1
        elif line.startswith('> '):
            insert_idx += 1
        elif line.startswith('#') or line.startswith('---'):
            break
        else:
            # First content line - check if it's an intro paragraph
            # Include it and any following non-empty lines
            while insert_idx < len(lines) and lines[insert_idx].strip() != '' and not lines[insert_idx].startswith('#'):
                insert_idx += 1
            break

    # Build the new file
    new_lines = lines[:insert_idx]

    # Add blockquote summary if not present
    if not has_blockquote:
        title = lines[title_line_idx]
        summary = create_summary_from_title(title)
        new_lines.append('')
        new_lines.append(f'> **LLM Quick Reference**: {summary}')

    new_lines.append('')
    new_lines.append(section)
    new_lines.append('')
    new_lines.append('---')
    new_lines.append('')

    # Add remaining content
    remaining_lines = lines[insert_idx:]
    # Skip leading empty lines and horizontal rules from remaining
    while remaining_lines and (remaining_lines[0].strip() == '' or remaining_lines[0].strip() == '---'):
        remaining_lines = remaining_lines[1:]

    new_lines.extend(remaining_lines)

    new_content = '\n'.join(new_lines)

    if dry_run:
        print(f'WOULD UPDATE: {filepath}')
        return True

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f'UPDATED: {filepath}')
    return True


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Move LLM Navigation sections to top of files')
    parser.add_argument('files', nargs='*', help='Files to process (default: find all in docs/spec)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be done without making changes')
    args = parser.parse_args()

    if args.files:
        files = args.files
    else:
        # Find all markdown files in docs/spec
        spec_dir = Path(__file__).parent.parent.parent
        files = list(spec_dir.rglob('*.md'))
        # Exclude files in .llm folder
        files = [f for f in files if '.llm' not in str(f)]

    modified = 0
    for f in files:
        filepath = str(f)
        if process_file(filepath, args.dry_run):
            modified += 1

    print(f'\nProcessed {len(files)} files, modified {modified}')


if __name__ == '__main__':
    main()
