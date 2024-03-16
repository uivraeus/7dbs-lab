distinctDigits = function(phone){
  let number = phone.components.number + '',
      seen = [],
      result = [],
      i = number.length;

  while(i--) {
    seen[+number[i]] = 1;
  }

  for (let i = 0; i < 10; i++) {
    if (seen[i]) {
      result[result.length] = i;
    }
  }

  return result;
}

db.system.js.insertOne({_id: 'distinctDigits', value: distinctDigits})
