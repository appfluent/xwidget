
Type getTypeOfNumberExpression(Type left, Type right) {
  if (left != right) {
    // One of them has to be double => whole expr is double
    return double;
  }
  return left;
}
