const fs = require("fs");
const jsonFormat = require("json-format");
class Package {
  prc_module_gateway(packageText) {
    return packageText.substring(
      packageText.search("prc_module_gateway"),
      packageText.length
    );
  }

  getOperationAndFunctionNames(text) {
    text = text.replace(/\s/g, "");
    const arrSplit = text.split("when");
    arrSplit.shift();

    const arrOperations = this.getOperations(arrSplit);
    const arrFunctionName = this.getFunctionName(arrOperations);

    return arrFunctionName;
  }

  getOperations(arr) {
    arr = arr.map((i) => {
      i = i.replace(`'`, "");
      i = i.replace(`'`, "");

      return i.split("then");
    });

    return arr;
  }

  getFunctionName(arrSplit) {
    const regex = /((?=prc_)|(?=fnc_)).*(?=\(p)/;

    arrSplit = arrSplit.map((i) => {
      const result = i[1].match(regex);
      if (result) {
        i[1] = result[0];

        return i;
      }
      return i;
    });

    return arrSplit;
  }

  writerInFile(path, operations) {
    fs.writeFileSync(path, jsonFormat(operations), { flag: "w" });
  }

  getParams(text) {
    console.log(text);
    if (text) {
      const rex = /^.*\/params\/.*$/gm;
      const list = text.match(rex);
      if (list) {
        const mapped = [];
        for (let i of list) {
          let temp = i
            .split(" ")
            .filter((i) => i != "" && i != "," && i != "path");
          mapped.push({ field: temp[0], type: temp[1], param: temp[2] });
        }
        return mapped;
      }
    }
  }

  getBodyPackage(text) {
    return text.substring(
      text.search("package body"),
      text.search("procedure prc_module_gateway")
    );
  }

  getFunctionsAndProcedures(body) {
    let bodySplit = body.split(/((?=procedure )|(?=function ))/);
    bodySplit = bodySplit.filter((i) => i !== "");
    bodySplit.shift();

    return bodySplit;
  }
}

module.exports = new Package();
