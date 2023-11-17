let dTable;
let size;
let columnCount;
let dataTableBody;

import Toast from "./toastNotification/Toast.js";

window.addEventListener('DOMContentLoaded', init);

function init() {
    const path = getPathFromURL();
    const maxSize = 5000000; // 5MB


    (async (path) => {
        const exists = await fileExists(path);
      
        if (exists) {
            setFile(path);
            displayFileSize(path)
            .then(() => {
                if (size <= maxSize){
                    createTable(path);
                } else {
                    createTablePart(path, maxSize);
                    toastIncompleteFile();
                    specifyIsPreview();
                }
            });
        } else {
            hideLoader();
            toastFileDoesntExist();
            fileNotFound();
        }
    })(path);
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
    let span = document.getElementById('fileSize');
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

function fileNotFound(){
    const strFileNotFound = "File not found";
    const fileName = document.getElementById('fileName');

    document.title = strFileNotFound;
    fileName.textContent = strFileNotFound;
    fileName.style.color = 'RED';
    document.getElementById('fileSize').textContent = "Null";
}

function specifyIsPreview(){
    const fileName = document.getElementById('fileName');
    var span = document.createElement("span");
    span.style.color = 'RED';
    span.textContent = 'Preview of '
    fileName.prepend(span);
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

async function fileExists(filePath) {
    if(!filePath){
        return false;
    }
    try {
        const response = await fetch(filePath);
        return response.ok;
    } catch (error) {
        console.error('Error:', error);
        return false;
    }
}

async function fetchPartialFile(url, maxSizeInBytes) {
    const rangeEnd = maxSizeInBytes - 1;
    const headers = { Range: `bytes=0-${rangeEnd}` };
  
    const response = await fetch(url, { headers });
    const blob = await response.blob();
    
    return blobToString(blob);
}

function blobToString(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
  
      reader.onloadend = () => {
        const text = reader.result;
        resolve(text);
      };
  
      reader.onerror = reject;
      reader.readAsText(blob);
    });
  }

function createTable(filePath) {
  fetch(filePath)
    .then(function(response) {
        return response.text();
    })
    .then(function(data) {
        var rows = data.trim().split(/\r?\n|\r/); 
        rowsToTable(rows);
    })
    .then(function() {
        initializeDataTable();
    });
}

function createTablePart(filePath, maxSize) {
    fetchPartialFile(filePath, maxSize)
    .then(function(data) {
        var rows = data.trim().split(/\r?\n|\r/); 
        rows.pop();
        rowsToTable(rows);
    })
    .then(function() {
        initializeDataTable();
    });
  }

function rowsToTable(rows) {
    // split the CSV rows
    
    if(rows.length > 0){
        var headerColumns = rows.shift().split('\t');
        columnCount = headerColumns.length;
        var headerRow = document.createElement('tr');
        headerColumns.forEach(columnTitle => {
            var th = document.createElement('th');
            th.textContent = columnTitle;
            headerRow.append(th);
        });
        document.getElementById('dataTableHead').appendChild(headerRow);
    }
    
    if(rows.length > 0){
        dataTableBody = document.getElementById('dataTableBody');

        rows.forEach(row => {
            var data = row.split(/\t/);
            var dataRow = document.createElement('tr');

            for(var i = 0 ; i < columnCount ; i++){
                var element = "";
                if (i < row.length){
                    element = data[i];
                }
                var td = document.createElement('td');
                td.textContent = element;
                dataRow.append(td);
            };
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

/***** Toast notifications **********************/
/************************************************/

function toastIncompleteFile(){
    new Toast({
        autoClose: 30000, // 30 seconds
        canCloseOnClick: true,
        darkMode: false,
        // callback function
        onClose: () => {},
        
        pauseOnHover: true,
        pauseOnFocusLoss: true,
        playNotificationSound: false,
        showProgressBar: true,

        toastContent: {
            title: "Incomplete file..",
            message: "The file is too big for viewing.\nAlthough you can download it from the top right corner !",
            type: "warning",
        },
        position: "bottom-right",
    });
}

function toastFileDoesntExist(){
    new Toast({
        autoClose: 900000, // 15 minutes
        canCloseOnClick: true,
        darkMode: false,
        // callback function
        onClose: () => {},
        
        pauseOnHover: true,
        pauseOnFocusLoss: true,
        playNotificationSound: false,
        showProgressBar: false,

        toastContent: {
            title: "file not found..",
            message: "Unfortunately, the file you are looking for doesn't exist...",
            type: "error",
        },
        position: "bottom-right",
    });
}
