reduce = function(key /*not used*/, values) {
  let total = 0;
  for (let i = 0; i < values.length; i++) {
    total += values[i].count;
  }
  return { count: total };
}
