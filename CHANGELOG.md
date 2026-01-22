# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.1] - 2026-01-22

### Changed
- Improved documentation and usage examples

### Fixed
- Fixed format selection in the UI

## [0.9.0] - 2026-01-22

### Added
- Support for `if`, `then`, `else`, and `not` keywords (conditional logic)
- Progressive disclosure for conditional logic and negation in the UI
- Support for `null` type
- UI state for property ordering

### Changed
- Major internal refactoring: introduced `SchemaMutator` to centralize schema transformations
- Simplified event handling and UI component data flow
- Performance optimization: Pre-compiled regex patterns in `SimpleValidator`
- Performance optimization: Efficient validation error lookup using tuple keys
- Performance optimization: Optimized `SchemaUtils.update_in_path/3` and schema validation logic
- Improved documentation for `Viewer` and `PrettyPrinter` modules
- Expanded test coverage including property-based tests for validator and mutator

### Fixed
- Removed redundant schema update logic when adding properties

## [0.8.0] - 2026-01-21

### Added
- New `JSONSchemaEditor.Viewer` component for standalone JSON display with syntax highlighting
- Structural punctuation highlighting in JSON viewer (braces, brackets, colons, commas)
- Indentation guides (vertical lines) in JSON viewer for better readability

### Changed
- `PrettyPrinter.format/1` now automatically decodes and pretty-prints JSON strings

## [0.7.3] - 2026-01-20

### Fixed
- Fixed Test Lab textarea not stretching to fill its container

## [0.7.2] - 2026-01-20

### Changed
- Increased the default height of the Sample JSON Data textarea in Test Lab

## [0.7.1] - 2026-01-20

### Added
- Quick-set default Schema URI button (inset into the URI input field)

## [0.7.0] - 2026-01-20

### Added
- Test Lab: Live validation of sample JSON against the edited schema
- Built-in `SimpleValidator` to support testing without external dependencies
- Improved button styles and disabled states

## [0.6.0] - 2026-01-20

### Added
- Undo/Redo support for the Visual Editor
- Standardized icons for better UI consistency

## [0.5.0] - 2026-01-20

### Added
- Schema Generation: Infer JSON Schema (Draft 07) from pasted JSON data
- Updated Import Modal to switch between 'Import Schema' and 'Generate from JSON' modes

## [0.4.0] - 2026-01-20

### Added
- Import functionality: Paste JSON from clipboard to hydrate the schema editor
- Import button and modal dialog

## [0.3.1] - 2026-01-19

### Fixed
- Fixed `BadMapError` when updating logic branches (e.g., `anyOf`) by adding list traversal support to `SchemaUtils`
- Removed forced alphabetical sorting of object properties to prevent UI jumping during renaming

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
