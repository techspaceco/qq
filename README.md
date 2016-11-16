# QQ

QQ improves puts debugging because most Ruby programmers are
[puts debuggers](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html).

Type `qq` instead of `pp`, `puts` etc are your variables will be pretty printed
to `q` in your temp directory.

## Why is this better than pp, puts, print?

* Less keystrokes.
* Pretty-printed objects, vars and expressions.
* No searching for redirected `$stderr`, `$stdout`.
* No log levels, locations or filtering to obscure your debugging.
* Pretty colors!

## Usage

```ruby
require 'qq'

# ...
qq(foo, bar, baz)
```

Tail `/tmp/q`.

## Haven't I seen this somewhere before?

Python programmers will recognize this as a less awesome port of the
[`q` module by zestyping](https://github.com/zestyping/q).

Ping does a great job of explaining `q` in his awesome lightning talk from
PyCon 2013:
[![ping's PyCon 2013 lightning talk](https://i.imgur.com/7KmWvtG.jpg)](https://youtu.be/OL3De8BAhME?t=25m14s)

Go developers may have seen [this `q` port by y0ssar1an](https://github.com/y0ssar1an/q).

Even if you don't write Go this port includes notes on shell setup, snippets
and autocomplete helpers for editors so it's worth a look if you use `q` in
any language.

## Install

```sh
gem install qq
```

## FAQ

### Why `qq` and not `q`?
Sadly there is already [this `q` gem](https://rubygems.org/gems/q).

### Is `qq` thread safe?
Yes

