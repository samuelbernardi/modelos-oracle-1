const axios = require("axios");
const env = require("../env/environment");

const BODY = {
  module: "",
  operation: "",
  parameters: {},
};

const OPTIONS = {
  headers: { "content-type": "application/json" },
};

function get(module, operation, parameters, options) {
  Object.assign(BODY, {
    module: env.modules[module],
    operation,
    parameters: {
      ...parameters
    },
  });

  Object.assign(OPTIONS, {
    ...options
  })

  return axios.post(env.base_url, BODY, OPTIONS);
}

module.exports = get;
