// operate on every "phone" within "phones"
map = function() {
  const digits = distinctDigits(this);
  emit({ // 1st arg: what will be the key
    digits: digits,
    country: this.components.country
  }, { // 2nd arg: what will be the value
    count: 1
  });
}