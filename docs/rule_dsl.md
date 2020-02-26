# @title Rule DSL
# @markup markdown

# Rule DSL Details

## Overview

### Rule Set

A _Rule Set_ is a hash where keys represent rule names and values represent _Rule Definitions_.

```
rule_set = {
    rule1: { fg: :red },
    rule2: { bg: :blue }
}
```

### Rule Definition

A _Rule Definition_ is a hash of options/actions that define a style rule. 

It can be organized on 1 of 3 ways:

- Defines options applied within rule (text directly covered by rule)
    - 'After' rule options will be auto-generated to reset any options within rule after its use
    - `{ rule: { fg: :red } }`
- Defines options applied within rule, and explicitly define 'after' rule options within `after:` attribute
    - Prevents auto-generation of 'after' rule options
    - `{ rule: { fg: :red, after: { reset: [:fg] } } }`
- Define inside and after rule options explicitly in their own groups
    - Functions the same as the previous approaches in that if no `after` section is explicitly defined, one will be auto generated
    - ` { rule: { inside: { fg: :red }, after: { reset: [:fg] } } }`

## Rule Definition Options/Actions

### Colors

#### Attributes

- `fg` - Change foreground color
- `bg` - Change background color

#### Values

##### Standard Named Colors

Color values can be color-name symbols as defined in {TermColor::Rule::Colors} (`:black, :red, :yellow, :blue, :magenta, :cyan, :white`)

##### XTerm 256 Color Values

To use XTerm 256 Color Mode values, include the color code integer inside a single item array. (E.g. for code `208`, use `[208]`)

##### XTerm 16m Color Values

To use XTerm 16m Color Mode RGB colors, include the red, green and blue color values in an ordered array (E.g. for 80 red, 80 green, 255 blue, use `[80,80,255]`)

### Styles

#### Actions

- `enable` - Style(s) to enable (Can be single item or array)
- `disable` - Style(s) to disable (Can be single item or array)

#### Values

(See symbols in {TermColor::Rule::Styles})

- `:bold`/`:intense`
- `:dim`/`:dark`
- `:italic`
- `:underline`
- `:inverse`
- `:strikethrough`

### Reset

Quick way of resetting one or more style rules. `reset` can be given a single symbol or an array of symbols

```ruby
{ reset: [options] }
```

#### Options

- `:fg` / `:bg` - Reset foreground / background color
- `:style` - Reset all styling
- `:all` - Reset all colors and styling

