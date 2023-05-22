
let dTable;
let size;
window.addEventListener('DOMContentLoaded', init);

/** TODO
 * Check if file exists (~parse text result)
 * Only load a part of bigger files and send a notification to user if the file is trimmed.
*/

function init() {
    const path = getPathFromURL();
    const maxSize = 5000000; // 5MB

    setFile(path);
    displayFileSize(path)
    .then(() => {
        if (size <= maxSize){
            createTable(path);
        } else {
            hideLoader();
            window.alert("This file is too heavy for displaying...\nBut you can download it from the top right corner !")
        }
    });
}

function hideLoader(){
    document.getElementById("loading").setAttribute("style", "display:none");
}

/***** Fill header content **********************/
/************************************************/

function displayFileSize(path) {
    return new Promise((resolve, reject) => {
        fetch(path)
            .then(response => response.headers.get("content-length"))
            .then(fileSize => {
                setFileSize(fileSize);
                resolve(fileSize);
            })
            .catch(error => reject(error));
    });
}

function setFile(path){
    const fileName = path.split("/").at(-1);
    document.title = fileName;
    document.getElementById('fileName').textContent = fileName;
    document.getElementById('download').setAttribute('href', path);
}

function setFileSize(fileSize){
    size = fileSize;
    span = document.getElementById('fileSize');
    if (fileSize >= 1000){
        fileSize = Math.round(fileSize / 1000 * 10) / 10;
        if (fileSize >= 1000){
            fileSize = Math.round(fileSize / 1000 * 10) / 10;
            if (fileSize >= 1000){
                fileSize = Math.round(fileSize / 1000 * 10) / 10;
                if (fileSize >= 1000){
                    fileSize = Math.round(fileSize / 1000 * 10) / 10;
                    span.textContent = fileSize + "TB";
                } else {
                    span.textContent = fileSize + "GB";
                }
            } else {
                span.textContent = fileSize + "MB";
            }
        } else {
            span.textContent = fileSize + "kB";
        }
    } else {
        span.textContent = fileSize + "B";
    }
}

/***** Fetch URL parameter **********************/
/************************************************/

function getPathFromURL(){
    var url_string = window.location.href;
    var url = new URL(url_string);
    var path = url.searchParams.get("path");
    return path
}

/***** Fetch CSV data and create DataTable ******/
/************************************************/

function createTable(filePath) {
  fetch(filePath)
    .then(function(response) {
        return response.text();
    })
    .then(function(data) {
        CSVToTable(data);
    })
    .then(function() {
        initializeDataTable();
    });
}

function CSVToTable(csvString) {
    // split the CSV rows
    var rows = csvString.trim().split(/\r?\n|\r/); 
    
    if(rows.length > 0){
        var headerColumns = rows.shift().split('\t');
        headerRow = document.createElement('tr');
        headerColumns.forEach(columnTitle => {
            th = document.createElement('th');
            th.textContent = columnTitle;
            headerRow.append(th);
        });
        document.getElementById('dataTableHead').appendChild(headerRow);
    }
    
    if(rows.length > 0){
        dataTableBody = document.getElementById('dataTableBody');

        rows.forEach(row => {
            var data = row.split(/\t/);
            dataRow = document.createElement('tr');
            data.forEach(element => {
                td = document.createElement('td');
                td.textContent = element;
                dataRow.append(td);
            });
            dataTableBody.appendChild(dataRow);
        });
    }
}


function initializeDataTable() {
    dTable = new DataTable('#dataTable', {
        responsive: true,
        "lengthMenu": [5, 10, 15, 20, 25, 50, 100],
        "pageLength": 15
    });

    hideLoader();
}