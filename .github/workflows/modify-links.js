const fs = require('fs');

const linksOutput = process.argv[2];
const modifiedLinks = modifyLinks(linksOutput);

// Replace your desired pattern using regular expressions
function modifyLinks(output) {
  const pattern = /example.com/g;
  const replacement = 'modified.com';
  const lines = output.split('\n');
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const match = line.match(/\[.+\]\((.+)\)/);
    
    if (match) {
      const link = match[1];
      if (link.match(pattern)) {
        const modifiedLink = link.replace(pattern, replacement);
        lines[i] = line.replace(link, modifiedLink);
      }
    }
  }
  
  return lines.join('\n');
}

fs.writeFileSync('.github/workflows/modified-links.md', modifiedLinks);
console.log(modifiedLinks);
