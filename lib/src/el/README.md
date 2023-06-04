# Operators

| Level | Category                 | Operator                                                                                                      | Associativity |
|-------|--------------------------|---------------------------------------------------------------------------------------------------------------|---------------|
| 16    | Unary Postfix            | `expr.`<br>`expr?.`<br>`expr++`<br>`expr--`<br>`expr1[expr2]`<br>`expr()`                                     |               |
| 15    | Unary Prefix             | `-expr`<br>`!expr`<br>`++expr`<br>`--expr`<br>`~expr`<br>`await expr`                                         |               |
| 14    | Multiplicative           | `*`<br>`/`<br>`~/`<br>`%`                                                                                     | Left-to-right |
| 13    | Additive                 | `+`<br>`-`                                                                                                    | Left-to-right |
| 12    | Shift                    | `<<`<br>`>>`<br>`>>>>`                                                                                        | Left-to-right |
| 11    | Bitwise AND              | `&`                                                                                                           | Left-to-right |
| 10    | Bitwise XOR              | `^`                                                                                                           | Left-to-right |
| 9     | Bitwise OR Postrix       | `&#124;`                                                                                                      | Left-to-right |
| 8     | Relational and Test Type | `<`<br>`>`<br>`<=`<br>`>=`<br>`as`<br>`is`<br>`is!`                                                           |               |
| 7     | Equality                 | `==`  <br>`!=`                                                                                                |               |
| 6     | Logical AND              | `&&`                                                                                                          | Left-to-right |
| 5     | Logical OR               | `&#124;&#124;`                                                                                                | Left-to-right |
| 4     | If null                  | `expr1 ?? expr2`                                                                                              | Left-to-right |
| 3     | Conditional              | `expr ? expr1 : expr2`                                                                                        | Right-to-left |
| 2     | Cascade                  | `..`                                                                                                          | Left-to-right |
| 1     | Assignment               | `=`<br>`*=`<br>`/=`<br>`+=`<br>`-=`<br>`&=`<br>`^=`<br>`<<=`<br>`>>=`<br>`??=`<br>`~/=.`<br>`&#124;=`<br>`%=` | Right-to-left |
