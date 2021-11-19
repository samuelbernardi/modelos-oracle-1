function prc_module_gateway(packageText) {
  return packageText.substring(
    packageText.search("prc_module_gateway"),
    packageText.length
  );
}

function getOperations(text) {
  let arrOperations = [];

  while (getOperation(text)) {
    let operation = text.substr(text.search("when"), text.search("then\n"))
    console.log(operation);
    arrOperations.push([getOperation(text), operation.substr(text.search("get"), text.search("then\n"))]);

    text = text.replace(getOperation(text), "");
  }

  return arrOperations;
}

function getOperation(text) {
  const rex = /((?=fnc_)).*(?=\()/;
  //   const rex = /((?=prc_)|(?=fnc_)).*(?=\()/;
  const result = text.match(rex);
  if (result) {
    return result[0];
  }
  return false;
}

module.exports = { prc_module_gateway, getOperations };
