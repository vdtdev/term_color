# TermColor

Rule-based text coloring/styling library for terminal text

## Overview

### Justifying Features

- Define named text style rules once, combining fg/bg color and styling that can be reused through out application
    - Able to manually specify what gets reset after style use is finished in a line, which parts to reset, etc.
- Streamline including multiple styles within a single string, including allowing nested rules

### TODO
- Publish as gem

### Requirements

- Tested/developed for Ruby 2.6.1

## Syntax

### Defining Style Rule Sets

A rule set is a hash of rule names mapped to hashes containing rules.

```
rules = TermColor.create_rule_set(rules_hash)
```

Each rule can either:

- Directly contain rule property/value pairs
- Contain rule property/value pairs within sub hashes with keys `a:` for rules to apply to text rule is used on and `z:` for rules to apply after application block closes (usually used for resetting colors/styling)
    - If neither `a:` or `z:` are given, rule properties are assumed to be for `a:`
    - If no `z:` is given, reset rules are automatically created to revert colors / styling enabled in `a:`
        - e.g.: `{fg: :red, enable: :underline}` will make a `z:` resetting fg and disabling underline


#### Rule Properties

- `fg` - Foreground color. Value can be a {TermColor::Rule::Colors} or an Integer or:
    - `{c256: Integer}` for ANSI 256 color
    - `{c16m: [red,green,blue]}` for ANSI 16m color
- `bg` - Background color. Value can be a {TermColor::Rule::Colors} or an Integer
    - `{c256: Integer}` for ANSI 256 color
    - `{c16m: [red,green,blue]}` for ANSI 16m color
- `enable` - Enable one or more styling options (({TermColor::Rule::Styles}))
- `disable` - Disable one or more styling options (({TermColor::Rule::Styles}))
- `reset` - Reset one or more properties. Can be `fg`, `bg` or `all` to reset everything

### Using Rule Sets

Calling `rule_set_instance.colorize()` on text will give back a string containing ANSI color codes.

- To start applying a rule, include `%rulename` in the text passed to `colorize`. The style will continue to be applied until `%%` is encountered. 
- When `%%` is encountered, if the rule has custom 'after' rules, those will take affect. (by default, style rules without custom 'after' rules will reset the colors/stylings they apply). If a rule was being applied prior to the application of the rule `%%` is closing, styling will revert back to that except for any overriding resets done by closing the inner style
- Including `%%` when a style rule is not actively being applied will reset fg, bg and styling settings to default.

## Examples

### Example 1

__Rules__

```
rules = TermColor.create_rule_set({
    # Underlined text
    title: { enable: :underline },
    # Yellow foreground
    name: { fg: :yellow },
    # Green foreground, italic
    prop: { fg: :green, enable: :italic }
})
```

__Use__

```
print rules.colorize("%titleHow to %propSucceed%%%% by %nameJohn%%\n")
```

__Result__

- "How to" - underlined
- "Succeed" - underlined + green + italic
- "by" - regular text
- "John" - yellow

## License

(c) 2020, Wade H. (vdtdev.prod@gmail.com). All Rights Reserved. Released under MIT license.