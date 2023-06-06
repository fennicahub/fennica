const fs = require('fs');
const yaml = require('js-yaml');

const bookdownConfig = fs.readFileSync('inst/examples/_bookdown.yml', 'utf-8');
const rmdFiles = yaml.load(bookdownConfig).rmd_files;
const files = rmdFiles.map(file => `inst/examples/_book/${file.replace('.Rmd', '.html')}`);
console.log(files.join(' '));
