# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-01-15

### Changed
- Major codebase refactor for simplicity and maintainability
- Consolidated and simplified event handlers
- Streamlined validation and schema utility functions
- Improved module documentation and usage examples
- Enhanced UI component data-driven rendering

## [0.2.0] - 2026-01-14

### Added
- Support for $schema field with Draft 07 default
- Tabbed interface with Visual Editor and JSON Preview
- JSON PrettyPrinter for formatted schema display
- Copy to Clipboard functionality for schema export
- Format support for string types (email, date-time, etc.)
- Strict Object Control (additionalProperties: false)
- Composition & Logic support (anyOf, oneOf, allOf)
- Collapsible nodes for better navigation
- Enum support with type-safe casting
- Validation constraints for all types
- Metadata fields (title, description)
- Required fields management
- Expandable description textarea
- Soft encapsulation support for custom classes and attributes

### Changed
- Improved CSS styling and organization
- Refactored component structure for better maintainability
- Enhanced UI/UX with better visual feedback
- Simplified README documentation
- Standardized schema update helpers
- Decoupled UI state from JSON Schema

### Removed
- Tailwind-specific CSS directives
- Redundant type labels from UI
- Packaging guide documentation

## [0.1.0] - 2026-01-14

### Added
- Initial release of JSON Schema Editor.
- Basic recursive schema editing support.
- Real-time validation.
- Phoenix LiveComponent integration.
