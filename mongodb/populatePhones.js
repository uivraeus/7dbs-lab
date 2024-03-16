populatePhones = function(area, start, stop) {
  let count = 0;
    
  for(let i = start; i < stop; i++) {
    const country = 1 + ((Math.random() * 8) << 0);
    const num = (country * 1e10) + (area * 1e7) + i;
    const fullNumber = "+" + country + " " + area + "-" + i;
    db.phones.insertOne({
      _id: num,
      components: {
        country: country,
        area: area,
        prefix: (i * 1e-4) << 0,
        number: i
      },
      display: fullNumber
    });
    count += 1;
    if ((count % 100) === 0) {
      print(`Inserted ${count} numbers, last inserted: ${fullNumber}`);
    }
  }
  print("Done!");
}
