# CHANGELOG

## [0.3.0] - TBD

### Added
- **Thread Safety**: Added optional `thread_safe: true` parameter for concurrent access
- **Enhanced Error Handling**: New exception hierarchy with `Registry::IndexNotFound`, `Registry::MissingAttributeError`
- **API Enhancements**: 
  - `exists?(criteria)` method for checking item existence
  - Better error messages with contextual information
- **Memory Management**: 
  - Automatic cleanup of method watching
  - `cleanup!` method for manual memory management
  - Tracking of watched objects to prevent memory leaks

### Changed
- Improved error messages with more context and suggestions
- Better handling of edge cases in `where` method
- Enhanced initialization to support new features

### Technical Improvements
- Added comprehensive test coverage for new features
- Improved code organization and documentation
- Better handling of thread safety concerns

## [0.2.0] - Previous Release
- Basic registry functionality
- Method watching for automatic reindexing
- Core indexing and querying capabilities