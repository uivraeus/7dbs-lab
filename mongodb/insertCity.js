function insertCity(name, population, lastCensus, famousFor, mayorInfo) {
  db.towns.insertOne({
    name,
    population,
    lastCensus: ISODate(lastCensus),
    famousFor,
    mayor: mayorInfo
  });
}
