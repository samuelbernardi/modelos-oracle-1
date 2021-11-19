const axios = require('axios');
const base_url = require('../env/environment').base_url;

const BODY = {
	"module": "LOGON",
	"operation": "LOGON",
	"parameters": {
		"username": "admincorp",
		"password": "kmm2020!#@kmm",
		"cod_gestao": 94522
	}
}

const OPTIONS = {
    headers: { 'content-type': 'application/json' },
  };


async function login(){
  return await axios.post(base_url, BODY, OPTIONS)
}

module.exports = login;