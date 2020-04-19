runtime! syntax/dosini.vim

syntax match Label "^\(Strings\|Configuration\):"
syntax match Error "^[^;][^=]*\.[^=]*="

"Following should be Error, but we doesn't have Error group, let's using Error
syntax match Error "^[^;][^=]*\s[^=]*="
syntax match Error "^[^;][^=]*=\s"
