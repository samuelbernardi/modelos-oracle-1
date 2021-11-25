const login = require("./services/login");
const fs = require("fs");
const get = require("./services/backend-call");
const Package = require("./services/package.js");

const path = "./packages/";
const arrPackageNames = fs.readdirSync(path);
console.log(arrPackageNames);

function onlyFileSql(packageName) {
  return packageName.search(".sql") != -1;
}

function dirName(packageName) {
  return packageName.replace(".sql", "").toLocaleLowerCase();
}

arrPackageNames.forEach((packageName) => {
  if (onlyFileSql(packageName)) {
    const file = fs.readFileSync(path + packageName, {
      encoding: "utf8",
    });
    const body = Package.getBodyPackage(file);
    const prc_module_gateway = Package.prc_module_gateway(file);
    const operations = Package.getOperationAndFunctionNames(prc_module_gateway);
    const proceduresAndFunctions = Package.getFunctionsAndProcedures(body);

    packageName = dirName(packageName);

    fs.mkdirSync(path + packageName, { recursive: true });
    Package.writerInFile(path + packageName + "/operations.json", operations);

    Package.writerInFile(
      path + packageName + "/body.json",
      proceduresAndFunctions
    );

    let items = [];
    items.push(packageName);

    operations.forEach((param) => {
      items.push(param);
      param.push(
        proceduresAndFunctions.filter((e) => {
          if (e.search(param[1]) !== -1) {
            return e;
          }
        })[0]
      );
    });

    items.forEach((item) => {
      if (typeof item !== "string") {
        const params = Package.getParams(item[2]);

        if (params)
          Package.writerInFile(`${path}${packageName}/${item[0]}.json`, params);
      }
    });
  }
});
