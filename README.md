*In design phase*

Bubble is a virtual machine designed as a rapid-prototype backend for the Boba programming language (also in design phase).

Current notable features:
- Stack-based virtual machine supporting functions of variable arity input/output
- Instructions supporting custom 'effect handlers'/'escape handlers' a la Daan Leijen's algebraic effect semantics (modified to support concatenative languages)
    - Can also be used for delimited continuations with some translation
- Instructions supporting algebraic data types

Design is in rapid flux, and will continue to change in tandem with the development of Boba. Expect this page to grow more detailed when Boba matures.