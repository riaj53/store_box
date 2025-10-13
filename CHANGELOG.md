# CHANGELOG.md

## 2.0.0

- **BREAKING:** The API has been completely refactored to be static. You no longer need to create an instance of `StoreBox`.
    - **Migration:** Change `final store = StoreBox(); await store.init();` to `await StoreBox.init();`.
- **FEAT:** Added a default box for simple, zero-configuration key-value storage with `StoreBox.put()` and `StoreBox.get()`.
- **FIX:** The package now works correctly on mobile devices by using `path_provider` to find the correct application documents directory.
- **FIX:** Fixed a bug where `Map` objects could not be read from the database.
- **FEAT:** Added `getAll()` method to `Box` to retrieve all items at once.

## 1.0.0

- Initial release.