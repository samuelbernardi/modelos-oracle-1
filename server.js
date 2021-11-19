const login = require("./services/login");
const fs = require("fs");
const jsonFormat = require("json-format");
const fileName = "./json/login";
const JsonToTS = require("json-to-ts");
const get = require("./services/backend-call");
const Package = require('./packages/services/services.js');

login().then((res) => {
  fs.writeFileSync(`${fileName}.json`, jsonFormat(res.data));
  const token = res.data.result.token;
  const options = {
    headers: {
      authorization: token,
    },
  };
  // get("operporto", "getEmbarcacao", { search: "MV" }, options)
  //   .then((res) => {
  //     fs.writeFileSync(`json/getEmbarcacao.json`, jsonFormat(res.data));
  //   })
  //   .catch((res) => {
  //     console.log(res);
  //   });
});



const file = fs.readFileSync(`./packages/pkg_operporto_backend.sql`, { encoding: "utf8" });
const prc_module_gateway = Package.prc_module_gateway(file);
const operations = Package.getOperations(prc_module_gateway);
console.log(operations);

// fs.writeFileSync(`${fileName}.ts`, JsonToTS(json));

// let str = 'interface MeuTeste { asd:string }'
// console.log(str.substring(str.search(' '), str.search(' {')));

// console.log(json);
