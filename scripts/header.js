document.addEventListener("DOMContentLoaded", () => {
    // Check if the current page is inside the "pages" folder
    let pathPrefix = window.location.pathname.includes("/pages/") ? "../" : "./";
    
    fetch(pathPrefix + "pages/header.html")
        .then(response => response.text())
        .then(data => {
            document.getElementById("header-placeholder").innerHTML = data;
        })
        .catch(error => console.error("Error loading header:", error));
});
