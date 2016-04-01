module krepel.container.utils;

private static import std.range;

/// Create a range from the given arguments.
///
/// Example: foreach(Integer; Only(1, 4, 9)) { Log.Info("The Integer: %d", Integer); }
// TODO(Manu): Find a better name?
alias Only = std.range.only;
